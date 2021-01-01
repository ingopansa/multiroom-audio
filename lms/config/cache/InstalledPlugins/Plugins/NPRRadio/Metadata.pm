package Plugins::NPRRadio::Metadata;

# $Id: $

use strict;

use Slim::Formats::RemoteMetadata;
use Slim::Utils::Log;
use Tie::Cache::LRU;
use Data::Dumper;

my $ICON = Plugins::NPRRadio::Plugin->_pluginDataFor('icon');
my $log   = logger('plugin.nprradio');

#  Hash holds for any URL the metadata found when parsing web page (e.g. American Routes) - sometimes the mp43 file data roverrides the more useful data & icon from the web page the  for playlist (e.g. http://....ram)  or rtsp url and associated image url froim iPlayer menu. 
tie my %urlmetadata, 'Tie::Cache::LRU', 32;

sub init {
	my $class = shift;

	$log->error("Register NPR meta provider, default icon=$ICON ");	
	Slim::Formats::RemoteMetadata->registerProvider(
		match => qr/npr\.org|americanroutes\.publicradio\.org|americanroutes\.s3\.amazonaws\.com/,
		func  => \&provider,
	);
}

# 		match => qr{mp3tunes\.com|squeezenetwork\.com/mp3tunes},

sub defaultMeta {
	my ( $client, $url ) = @_;

	
	return {
		title => Slim::Music::Info::getCurrentTitle($url),
		icon  => $ICON,
		cover => $ICON,
		type  => $client->string('RADIO'),
	};
}

sub set_urlmetadata {
	my $url = shift;
	my $metadata = shift;
#
# BBC use the following images sizes: 86x48 150x84 178x100 512x288 528x297 640x360
# so change requested size to size to suit Squeezeplay - otherwise image is streched
# and fuzzy.
#
	$urlmetadata{$url} = $metadata;
}


sub get_urlmetadata {
	my $url = shift;
	if ( defined($urlmetadata{$url}) ) {
# $log->debug("Metedata " . Dumper($urlmetadata{$url}));
		return $urlmetadata{$url} ;
	} 

	return undef;
}


sub provider {
	my ( $client, $url ) = @_;
#	$log->error("Called NPR meta provider url=$url ");	
	my $meta = get_urlmetadata ($url);
	if (defined($meta)) {
		Slim::Music::Info::setCurrentTitle( $url, $meta->{'title'} . "  ". $meta->{'artist'}  );
	} else {
		$meta = defaultMeta( $client, $url );
	};
			

#	my $metadata = defined(get_urlmetadata ($url)) ? get_urlmetadata ($url)  : defaultMeta( $client, $url )  ;

	return $meta;
}

1;