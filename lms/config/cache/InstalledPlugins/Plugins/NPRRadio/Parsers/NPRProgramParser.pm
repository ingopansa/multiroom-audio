#
#
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License, version 2.
#
#
package Plugins::NPRRadio::Parsers::NPRProgramParser;

use strict;

use Slim::Utils::Log;

use HTML::PullParser;

my $log = logger('plugin.nprradio');

use Data::Dumper;

sub getnexttag
{
    my $t;
    my $p         = shift;
    my $searchtag = shift;
    my $exittag   = shift ;

    for (;;) {
        $t = $p->get_token();
        return undef unless (defined($t));
        return $t if ( $t->[1] eq $searchtag) ;
        return $t if ( defined ($exittag) && $t->[1] eq $exittag) ;
    }
}

sub getnext2tag
{
  my $t;
  my ($p,$searchtag,$endsearchtag) = @_;

  for (;;) {
     $t = $p->get_token();
     return undef unless (defined($t));
     return $t if ( $t->[1] eq $endsearchtag) ;
     return $t if ( $t->[1] eq $searchtag) ;

#     print "discard nexttag ". $t->[1]."\n";
  }
}

sub parse
{
    my $class  = shift;
    my $http   = shift;

    my $params = $http->params('params');
    my $url    = $params->{'url'};
    my $client = $params->{client};

    my $savedstreams;
    my $itemslist;
    my $programtitle;
    my $previoushref;
    my $t;
    my $firstitem = 1;

    my $p = HTML::PullParser->new(api_version => 3, doc => ${$http->contentRef},
                                  start => 'event, tag, attr,  skipped_text',
                                  end   => 'event, tag, dtext, skipped_text',
                                  report_tags => [qw ( title p a ul li )]);

	$t = getnexttag($p,"title");
	$t = getnexttag($p,"/title");
	$programtitle = $t->[3];
	$programtitle =~ s/NPR.org Text-Only ://; 

	$t = getnexttag($p,"/p");
	$t = getnexttag($p,"/p");
	$t = getnexttag($p,"/p");
	$t = getnexttag($p,"a");
	return undef if (!defined($t));

	$previoushref = (defined($t->[2]->{href})) ? $t->[2]->{href} : undef;
	$t = getnexttag($p,"/a");
	return undef unless ($t->[3] =~ m/&laquo; Previous/ );

	push @$savedstreams, {
		'name'   => 'Previous program',
		'parser' => 'Plugins::NPRRadio::Parsers::NPRProgramParser',
		'url'    => 'http://thin.npr.org' . $previoushref,
	} ;

	$log->debug("Previous URL =" . 'http://thin.npr.org' . $previoushref);
	$t = getnexttag($p,"ul");

	while (defined($t =  getnext2tag($p,"li","/ul"))) {
		last if ($t->[1] eq "/ul");
	
		$t = getnexttag($p,"a");
		my $progtitle = $t->[3];
		my $proghref  = $t->[2]->{href};
		$t = getnexttag($p,"/a");
		$progtitle .= 	$t->[3];
		$log->debug("Item title=$progtitle  Item Url=http://thin.npr.org$proghref");
		push @$itemslist , "http://thin.npr.org$proghref&foolcache=1";

		if ($firstitem) {
			push @$savedstreams, {
			'name'   => 'Play all items',
			'parser' => 'Plugins::NPRRadio::Parsers::NPRPlayAllParser',
			'url'    => 'http://thin.npr.org' . $proghref. '&foolcache=1' ,
			'type'   => 'playlist',
			'on_select'   => 'play',
			} ;
			$firstitem = 0;
			$itemslist = undef;
		}
		push @$savedstreams, {
			'name'   => $progtitle,
			'url'    => 'http://thin.npr.org' . $proghref,
			'parser' => 'Plugins::NPRRadio::Parsers::NPRPlayableParser',
			'type'   => 'playlist',
			'on_select'   => 'play',
#			'description' => $progdesc,
			};
	}

# Client is undefined if there is no player attached - so no need for play all items menu items.
# If there are no items in the itemslist, the program has only one playable item - so no "play all items" menu
	# return xmlbrowser hash
	if ( (!defined($itemslist) ) || (!defined($client)) ) {
		splice(@$savedstreams,1,1);

	} else {
		 $client->pluginData('nprplayall'=> \@$itemslist);
	}

	return {
		'type'  => 'opml',
#		'title' => $params->{'feedTitle'},
		'title' => $programtitle,
		'items' => \@$savedstreams,
	};

}
# Local Variables:
# tab-width:4
# indent-tabs-mode:t
# End:

1;
