package Plugins::SqueezeCloud::ProtocolHandler;

# Plugin to stream audio from SoundCloud streams
#
# Released under GNU General Public License version 2 (GPLv2)
# Written by David Blackman (first release), Robert Gibbon (improvements),
#   Daniel Vijge (improvements)
# See file LICENSE for full license details

use strict;

use base qw(Slim::Player::Protocols::HTTPS);

use List::Util qw(min max);
use LWP::Simple;
use LWP::UserAgent;
use HTML::Parser;
use URI::Escape;
use JSON::XS::VersionOneAndTwo;
use XML::Simple;

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Utils::Errno;
use Slim::Utils::Cache;
use Scalar::Util qw(blessed);

my $log   = logger('plugin.squeezecloud');

my %fetching; # hash of ids we are fetching metadata for to avoid multiple fetches

Slim::Player::ProtocolHandlers->registerHandler('soundcloud', __PACKAGE__);

use strict;
use base 'Slim::Player::Protocols::HTTP';

my $CLIENT_ID = "112d35211af80d72c8ff470ab66400d8";
my $prefs = preferences('plugin.squeezecloud');

$prefs->init({ apiKey => "", playmethod => "stream" });

sub canSeek { 0 }

sub addClientId {
	my ($url) = shift;

	my $prefix = "?";

	if ($url =~ /\?/) {
		my $prefix = "&";		
	}
	
	my $decorated = $url . $prefix . "client_id=$CLIENT_ID";

	if (0 && $prefs->get('apiKey')) {
		my $decorated = $url . $prefix . "oauth_token=" . $prefs->get('apiKey');
		$log->info($decorated);
	}
	return $decorated;
}

sub _makeMetadata {
	my ($json) = shift;

	my $DATA = {
		duration => int($json->{'duration'} / 1000),
		name => $json->{'title'},
		title => $json->{'title'},
		artist => $json->{'user'}->{'username'},
		album => " ",
		#type => 'soundcloud',
		#play => addClientId(getStreamURL($json)),
		#url  => $json->{'permalink_url'},
		#link => "soundcloud://" . $json->{'id'},
		bitrate   => '320kbps',
		type      => 'MP3 (SoundCloud)',
		#info_link => $json->{'permalink_url'},
		icon => getBetterArtworkURL($json->{'artwork_url'} || ""),
		image => getBetterArtworkURL($json->{'artwork_url'} || ""),
		cover => getBetterArtworkURL($json->{'artwork_url'} || ""),
	};
}

sub getStreamURL {
	my $json = shift;

	if ($prefs->get('playmethod') eq 'download' && exists($json->{'download_url'}) && defined($json->{'download_url'}) && $json->{'downloadable'} eq '1') {
		return $json->{'download_url'};
	}
	else {
		return $json->{'stream_url'};
	}
}

sub getBetterArtworkURL {
	my $artworkURL = shift;
	$artworkURL =~ s/-large/-t500x500/g;
	return $artworkURL;
}

sub getFormatForURL () { 'mp3' }

sub isRemote { 1 }

sub scanUrl {
	my ($class, $url, $args) = @_;
	$args->{cb}->( $args->{song}->currentTrack() );
}

sub gotNextTrack {
	my $http   = shift;
	my $client = $http->params->{client};
	my $song   = $http->params->{song};     
	my $url    = $song->currentTrack()->url;
	my $track  = eval { from_json( $http->content ) };

	if ( $@ || $track->{error} ) {

		# We didn't get the next track to play
		if ( $log->is_warn ) {
			$log->warn( 'Soundcloud error getting next track: ' . ( $@ || $track->{error} ) );
		}

		if ( $client->playingSong() ) {
			$client->playingSong()->pluginData( {
				songName => $@ || $track->{error},
			} );
		}
	
		$http->params->{'errorCallback'}->( 'PLUGIN_SQUEEZECLOUD_NO_INFO', $track->{error} );
		return;
	}
	
	# Save metadata for this track
	$song->pluginData( $track );

	my $stream = addClientId(getStreamURL($track));
	$log->info($stream);

	my $ua = LWP::UserAgent->new(
		requests_redirectable => [],
	);

	my $res = $ua->get($stream);

	my $redirector = $res->header( 'location' );
	$song->streamUrl($redirector);

	my $meta = _makeMetadata($track);
	$song->duration( $meta->{duration} );

	my $cache = Slim::Utils::Cache->new;
	$log->info("setting ". 'soundcloud_meta_' . $track->{id});
	$cache->set( 'soundcloud_meta_' . $track->{id}, $meta, 86400 );

	$http->params->{callback}->();
}

sub gotNextTrackError {
	my $http = shift;

	$http->params->{errorCallback}->( 'PLUGIN_SQUEEZECLOUD_ERROR', $http->error );
}

sub getNextTrack {
	my ($class, $song, $successCb, $errorCb) = @_;
		
	my $client = $song->master();
	my $url    = $song->currentTrack()->url;
		
	# Get next track
	my ($id) = $url =~ m{^soundcloud://(.*)$};
		
	# Talk to SN and get the next track to play
	my $trackURL = addClientId("https://api.soundcloud.com/tracks/" . $id . ".json");
		
	my $http = Slim::Networking::SimpleAsyncHTTP->new(
		\&gotNextTrack,
		\&gotNextTrackError,
		{
			client        => $client,
			song          => $song,
			callback      => $successCb,
			errorCallback => $errorCb,
			timeout       => 35,
		},
	);
		
	main::DEBUGLOG && $log->is_debug && $log->debug("Getting track from soundcloud for $id");
		
	$http->get( $trackURL );
}

# To support remote streaming (synced players, slimp3/SB1), we need to subclass Protocols::HTTP
sub new {
	my $class  = shift;
	my $args   = shift;

	my $client = $args->{client};

	my $song      = $args->{song};
	my $streamUrl = $song->streamUrl() || return;
	my $track     = $song->pluginData();

	$log->info( 'Remote streaming Soundcloud track: ' . $streamUrl );

	my $sock = $class->SUPER::new( {
		url     => $streamUrl,
		song    => $song,
		client  => $client,
	} ) || return;

	${*$sock}{contentType} = 'audio/mpeg';

	return $sock;
}


# Track Info menu
sub trackInfo {
	my ( $class, $client, $track ) = @_;

	my $url = $track->url;
	$log->info("trackInfo: " . $url);
}

# Track Info menu
sub trackInfoURL {
	my ( $class, $client, $url ) = @_;
	$log->info("trackInfoURL: " . $url);
}

use Data::Dumper;
# Metadata for a URL, used by CLI/JSON clients
sub getMetadataFor {
	my ( $class, $client, $url ) = @_;
	
	return {} unless $url;

	#$log->info("metadata: " . $url);

	my $icon = $class->getIcon();
	my $cache = Slim::Utils::Cache->new;

	# If metadata is not here, fetch it so the next poll will include the data
	my ($trackId) = $url =~ m{soundcloud://(.+)};
	#$log->info("looking for  ". 'soundcloud_meta_' . $trackId );
	my $meta      = $cache->get( 'soundcloud_meta_' . $trackId );

	if ( !$meta && !$client->master->pluginData('fetchingMeta') ) {
		# Go fetch metadata for all tracks on the playlist without metadata
		my @need;

		for my $track ( @{ Slim::Player::Playlist::playList($client) } ) {
			my $trackURL = blessed($track) ? $track->url : $track;
			if ( $trackURL =~ m{soundcloud://(.+)} ) {
				my $id = $1;
				if ( !$cache->get("soundcloud_meta_$id") ) {
					push @need, $id;
				}
			}
		}
		
		if ( main::DEBUGLOG && $log->is_debug ) {
			$log->debug( "Need to fetch metadata for: " . join( ', ', @need ) );
		}
		
		# $client->master->pluginData( fetchingMeta => 1 );
		
		# my $metaUrl = Slim::Networking::SqueezeNetwork->url(
		# 	"/api/classical/v1/playback/getBulkMetadata"
		# );
		
		# my $http = Slim::Networking::SqueezeNetwork->new(
		# 	\&_gotBulkMetadata,
		# 	\&_gotBulkMetadataError,
		# 	{
		# 			client  => $client,
		# 			timeout => 60,
		# 	},
		# );

		# $http->post(
		# 	$metaUrl,
		# 	'Content-Type' => 'application/x-www-form-urlencoded',
		# 	'trackIds=' . join( ',', @need ),
		# );
	}

	#$log->debug( "Returning metadata for: $url" . ($meta ? '' : ': default') );

	return $meta || {
		bitrate   => '320kbps',
		type      => 'MP3 (SoundCloud)',
		icon      => $icon,
		cover     => $icon,
	};
}

sub canDirectStreamSong {
	my ( $class, $client, $song ) = @_;

	# We need to check with the base class (HTTP) to see if we
	# are synced or if the user has set mp3StreamingMethod
	return $class->SUPER::canDirectStream( $client, $song->streamUrl(), $class->getFormatForURL() );
}

# If an audio stream fails, keep playing
sub handleDirectError {
	my ( $class, $client, $url, $response, $status_line ) = @_;

	main::INFOLOG && $log->info("Direct stream failed: $url [$response] $status_line");

	$client->controller()->playerStreamingFailed( $client, 'PLUGIN_SQUEEZECLOUD_STREAM_FAILED' );
}

sub explodePlaylist {
	my ( $class, $client, $uri, $callback ) = @_;

	if ( $uri =~ Plugins::SqueezeCloud::Plugin::PAGE_URL_REGEXP ) {
		Plugins::SqueezeCloud::Plugin::urlHandler(
			$client,
			sub { $callback->([map {$_->{'play'}} @{$_[0]->{'items'}}]) },
			{'search' => $uri},
		);
	}
	else {
		$callback->([$uri]);
	}
}

1;
