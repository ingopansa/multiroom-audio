#
#
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License, version 2.
#
#
package Plugins::NPRRadio::Parsers::AmericanRoutesArtistParser;

use strict;

use Slim::Utils::Log;

use HTML::PullParser;

my $log = logger('plugin.nprradio');

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

sub cleanup
{
    my $str = shift;
    return undef unless defined ($str); 

    $str =~ s/\n/ /g;  # change LF to space
    $str =~ s/\r//g;   # Get rid of CR if any.

    $str =~ s/<br>//gi; # Get rid of HTML <br> if any.
    $str =~ s/<br \/>//gi; # Get rid of HTML <br> if any.

    $str =~ s/&nbsp;/ /g; # replace HTML &nbsp if any.

    # strip whitespace from beginning and end

    $str =~ s/^\s*//; 
    $str =~ s/\s*$//; 

    return $str;
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
    my $artistlabel;
    my $artisthref;
    my $artistimg;

    my $t;
    my $menuname = $params->{'item'}->{'name'}; 
    my $p = HTML::PullParser->new(api_version => 3, doc => ${$http->contentRef},
                                  start => 'event, tag, attr,  skipped_text',
                                  end   => 'event, tag, dtext, skipped_text',
                                  report_tags => [qw ( h2 h3 div table tr td a img )]);

	$log->debug("Begin");

	while (defined($t =  getnexttag($p,'div'))) {
		next if (!defined ($t->[2]->{id}));
		last if  ( ($t->[2]->{id} eq "artists-list") ) ;
	}
	return undef if (!defined($t));
#
	$t = getnexttag($p,"table");
	while (defined($t =  getnexttag($p,"tr"))) {

		while (defined($t = getnexttag($p,"td"))) {
			next if (!defined ($t->[2]->{class}));
			next if ($t->[2]->{class} ne "image") ;

			$t = getnexttag($p,"a");
			if (defined ($t->[2]->{href})) {
				$artisthref = $t->[2]->{href};
				$t = getnexttag($p,"img");
				if (defined ($t->[2]->{src})) {
					$artistimg = $t->[2]->{src};
				}
			}
			$t = getnexttag($p,"/a");
			$t = getnexttag($p,"td");
			next if (!defined ($t->[2]->{class})) ;
			next if ($t->[2]->{class} ne "label") ;

			$t = getnexttag($p,"a");
			if (defined ($t->[2]->{href})) {
				$artisthref = $t->[2]->{href};
			}
			$t = getnexttag($p,"/a");
			$artistlabel = cleanup($t->[3]);
			push @$savedstreams, {
				'name'   => $artistlabel,
				'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesArtistProgParser',
				'url'    => 'http://americanroutes.publicradio.org' . $artisthref,
				'icon'    => 'http://americanroutes.publicradio.org' . $artistimg,
			} ;
		}
	}


	return {
		'type'  => 'opml',
		'title' => $menuname,
		'items' => \@$savedstreams,
	};

}

# Local Variables:
# tab-width:4
# indent-tabs-mode:t
# End:

1;
