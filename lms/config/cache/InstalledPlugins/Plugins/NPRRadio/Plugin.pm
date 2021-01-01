
package Plugins::NPRRadio::Plugin;

use strict;

use base qw(Slim::Plugin::OPMLBased);

use Slim::Utils::Log;
use Slim::Utils::Prefs;

# create log categogy before loading other modules
my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.nprradio',
	'defaultLevel' => 'WARN',
	'description'  => getDisplayName(),
});

my $prefsServer = preferences('server');

use File::Spec::Functions qw(:ALL);

use Slim::Utils::Misc;
use Slim::Utils::Strings;
use Slim::Plugin::Favorites::Opml;
use Plugins::NPRRadio::Settings;
use Plugins::NPRRadio::Metadata;

my $menuUrl; # store the menu url here

# Main plugin is a subclass of OPMLBased - not much to do here:

sub initPlugin {
	my $class = shift;

	$log->info("Initialising " . $class->_pluginDataFor('version'));

#	Slim::Player::ProtocolHandlers->registerIconHandler(
#		qr/thin\.npr\.org/, 
#		sub { return $class->_pluginDataFor('icon'); }
#	);


	Plugins::NPRRadio::Settings->new($class);

	$class->SUPER::initPlugin(
		feed => $class->menuUrl,
		tag  => 'npr',
		menu => 'radios'
	);

	Plugins::NPRRadio::Settings->importNewMenuFiles;
        Plugins::NPRRadio::Metadata->init();
}

sub setMode {
	my $class  = shift;
	my $client = shift;

	# don't push into xmlbrowser for scanning mode
	return if $client->modeParam('scan');

	$class->SUPER::setMode($client, @_);
}

sub menuUrl {
	my $class = shift;

	return $menuUrl if $menuUrl;

	my $dir = $prefsServer->get('playlistdir');

	if (!$dir || !-w $dir) {
		$dir = $prefsServer->get('cachedir');
	}

	my $file = catdir($dir, "nprradio.opml");

	$menuUrl = Slim::Utils::Misc::fileURLFromPath($file);

	if (-r $file) {

		if (-w $file) {
			$log->info("nprradio menu file: $file");

		} else {
			$log->warn("unable to write to nprradio menu file: $file");
		}

	} else {

		$log->info("creating nprradio menu file: $file");

		my $newopml = Slim::Plugin::Favorites::Opml->new;
		$newopml->title(Slim::Utils::Strings::string('PLUGIN_NPRRADIO'));
		$newopml->save($file);

		Plugins::NPRRadio::Settings->importNewMenuFiles('clear');
	}

	return $menuUrl;
}

sub pluginDir {
	shift->_pluginDataFor('basedir');
}

sub modeName { 'NPRRADIO' };

sub getDisplayName { 'PLUGIN_NPRRADIO' };

1;
