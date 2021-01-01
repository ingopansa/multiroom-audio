#
#
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License, version 2.
#
#
package Plugins::NPRRadio::Parsers::AmericanRoutesPlayableParser;

use strict;

use Slim::Utils::Log;
use URI::Escape;


my $log = logger('plugin.nprradio');

sub parse
{
    my $class  = shift;
    my $http   = shift;

    $log->debug('Begin');


    my $params = $http->params('params');
    my $url    = $params->{'url'};

    my $newurl = ${$http->contentRef};
    my $playurl;


	    my %ops = map {
			my ( $k, $v ) = split( '=' );
			$k  => uri_unescape( $v )
	  } split( '&', $newurl );

	$playurl = $ops{'file'};

	my $metadata = {
			'title'       => $params->{'metaartist'},
			'artist'      => $params->{'item'}->{'metatitle'},
			'icon'        => $params->{'item'}->{'icon'},
			'cover'       => $params->{'item'}->{'icon'},
			'description' => $params->{'item'}->{'description'},
	};

	Plugins::NPRRadio::Metadata::set_urlmetadata($playurl,$metadata) ;
	return {
		'type'  => 'opml',
		'icon' => $params->{'item'}->{'icon'},
		'items' => [ {
			'name'  => $params->{'item'}->{'name'} || $params->{'item'}->{'title'},
			'url'   => $playurl,
			'type'  => 'audio',
			'icon'  => $params->{'item'}->{'icon'},
			'cover' => $params->{'item'}->{'icon'},
			'description' => $params->{'item'}->{'description'},
		} ],
	};
}

# Local Variables:
# tab-width:4
# indent-tabs-mode:t
# End:

1;
