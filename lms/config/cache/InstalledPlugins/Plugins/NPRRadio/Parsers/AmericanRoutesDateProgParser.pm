#
#
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License, version 2.
#
#
package Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser;

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

    $str =~ s/<i>//gi; # Get rid of HTML <i> if any.
    $str =~ s/<\/i>//gi; # Get rid of HTML </i> if any.


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

    my $savedstreams;
    my $showplaylist;
    my $progid;
    my $progdesc;
    my $progtitle;
    my $progdate;
    my $progimg;

    my $t;
    my $menuname = $params->{'item'}->{'name'}; 

    $log->debug('Begin');

    my $p = HTML::PullParser->new(api_version => 3, doc => ${$http->contentRef},
                                  start => 'event, tag, attr,  skipped_text',
                                  end   => 'event, tag, dtext, skipped_text',
                                  report_tags => [qw ( h2 h3 p div table tr td a img)]);


	while (defined($t =  getnexttag($p,'div'))) {
		next if (!defined ($t->[2]->{id}));
		last if  ($t->[2]->{id} eq "shows-list") ;
	}
	return undef if (!defined($t));
	$t = getnexttag($p,"table");


	while (defined($t =  getnexttag($p,"tr"))) {
		$t = getnexttag($p,"td"); 
		$log->debug("Got table td ");

		next if (!defined ($t->[2]->{class})) ;
		next if ($t->[2]->{class} ne "title") ;

		$t = getnexttag($p,"h2");
		$t = getnexttag($p,"/h2");
		$progdate = cleanup($t->[3]);
		$t = getnexttag($p,"h3");
		$t = getnexttag($p,"/h3");
		$progtitle = cleanup($t->[3]);

		$t = getnexttag($p,"td");
		$t = getnexttag($p,"td");

		next if (!defined ($t->[2]->{class}));
		next if ($t->[2]->{class} ne "image") ;

		$t = getnexttag($p,"img");
		if (defined ($t->[2]->{src})) {
			$progimg = "http://americanroutes.publicradio.org" .$t->[2]->{src};
		}

		$t = getnexttag($p,"p");
		next if (!defined ($t->[2]->{class})) ;
		next if ($t->[2]->{class} ne "desc") ;
		$t = getnexttag($p,"/p");
		$progdesc = cleanup($t->[3]);

		my $partno = 1;
		$showplaylist = undef;
		while (defined($t =  getnext2tag($p,'a','/p'))) {
			last if ($t->[1] eq '/p') ;
			next if (!defined ($t->[2]->{class}));
			next if  ( ($t->[2]->{class} ne "listen") ) ;
			my $metatitle = $progtitle;
			my $metaartist;
				
			$metatitle =~s/: FULL SHOW//ig;
			$metatitle =~s/: INTERVIEW//ig;
			$metatitle =~s/: SEGMENT//ig;
			$metatitle .= ' ' . $progdate;
			$metaartist = $progdate . " - part $partno" ;

			push @$showplaylist, {
				'name'   => $progtitle . " - part $partno",
				'title'  => $progtitle . " - part $partno",
				'url'    => 'http://americanroutes.publicradio.org/ajax' . $t->[2]->{href},
				'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesPlayableParser',
				'type'   => 'playlist',
				'description' => $progdesc,
				'icon'   => $progimg,
				'metatitle'   => $metatitle ,
				'metaartist'  => $metaartist,
			} ;
			$partno++;
		};

		if (defined($showplaylist)) {
			push @$savedstreams, {
				'title'  => $progtitle,
				'name'   => $progtitle,
				'type'   => 'opml',
				'items'  => \@$showplaylist,
				'icon'   => $progimg,
			} ;
		} ;
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
