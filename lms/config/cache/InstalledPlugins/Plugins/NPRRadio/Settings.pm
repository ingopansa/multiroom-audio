#
# NPRRadio Copyright (C) Jules Taplin, Craig Eales, Triode, Neil Sleightholm, Bryan Alton 2004-2008
#
# $Id: Settings.pm,v 1.10 2008/01/05 10:06:23 neil Exp $
#
# This plugin is free software; you can redistribute it and/or modify it 
# under the terms of the GNU General Public License, version 2.
#
package Plugins::NPRRadio::Settings;

use strict;
use base qw(Slim::Web::Settings);

use File::Next;

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Plugin::Favorites::Opml;
use Data::Dumper;

my $log   = logger('plugin.nprradio');
my $prefs = preferences('plugin.nprradio');

# TODO
#
#  Prefs for clikey
#  prefs for audio type - WM, RM MP3
#
#
my $plugin; # the main plugin class

sub name {
	return 'PLUGIN_NPRRADIO';
}

sub page {
	return 'plugins/NPRRadio/settings/basic.html';
}

sub new {
	my $class = shift;
	$plugin   = shift;

	$class->SUPER::new;
}

sub handler {
	my ($class, $client, $params) = @_;

	if ($params->{'saveSettings'}) {

		# Remove empty feeds.
	}

	if ($params->{'reset'}) {

		$prefs->set('imported', {});
		$class->importNewMenuFiles('clear');
	}

	$params->{'opmlfile'} = $plugin->menuUrl;

	return $class->SUPER::handler($client, $params);
}

sub importNewMenuFiles {
	my $class = shift;
	my $clear = shift;

	my $imported = $prefs->get('imported');

	if (!defined $imported || $clear) {
		$imported = {};
		$clear ||= 'clear';
	}

	$log->info($clear ? "clearing old menu" : "searching for new menu files to import");

	my @files = ();
	my $iter  = File::Next::files({ 'file_filter' => sub { /\.opml$/ }, 'descend_filter' => sub { $_ ne 'HTML' } }, $plugin->pluginDir );

	while (my $file = $iter->()) {
		if ( !$imported->{ $file } || (stat($file))[9] > $imported->{ $file } ) {
			push @files, $file;
			$imported->{ $file } = time;
		}
	}

	if (@files) {
		$class->_import($clear, \@files);
		$prefs->set('imported', $imported);
	}
}

sub _import {
	my $class = shift;
	my $clear = shift;
	my $files = shift;

	my $menuOpml = Slim::Plugin::Favorites::Opml->new({ 'url' => $plugin->menuUrl });

	if ($clear) {
		splice @{$menuOpml->toplevel}, 0;
	}

	for my $file (sort @$files) {

		$log->info("importing $file");
	
		my $import = Slim::Plugin::Favorites::Opml->new({ 'url' => $file });
		$log->debug("Import title >". $import->title . "<");
		if ($import->title eq 'NPR Radio') {

			for my $entry (reverse @{$import->toplevel}) {

				$log->debug("Entry\n ". Dumper($entry) . "\n");

				# remove any previously matching toplevel entry
				my $i = 0;
				
				for my $existing (@{ $menuOpml->toplevel }) {

					if ($existing->{'text'} eq $entry->{'text'}) {
						splice @{ $menuOpml->toplevel }, $i, 1;
						last;
					}
					++$i;
				}
				# add in new entry
				unshift @{ $menuOpml->toplevel }, $entry;
			}

		} else {

			my $entry;
#			$log->info("Imported\n ". Dumper($import) . "\n");

			if (scalar @{ $import->toplevel } == 1) {
				$entry = $import->toplevel->[0];
			} else {
				$entry = {
					'text'    => $import->title,
					'outline' => $import->toplevel,
					'icon' => "plugins/NPRRadio/html/images/nprradio.png",
				};
			}

			# remove any previously matching toplevel entry
			my $i = 0;

			for my $existing (@{ $menuOpml->toplevel }) {

				if ($existing->{'text'} eq $entry->{'text'}) {
					splice @{ $menuOpml->toplevel }, $i, 1;
					last;
				}

				++$i;
			}

			# add in the new version
			push @{ $menuOpml->toplevel }, $entry;
		}
	}

	$menuOpml->save;
}


1;
