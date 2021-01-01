#
#
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License, version 2.
#
#
package Plugins::NPRRadio::Parsers::NPRTopicParser;

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


sub cleanup
{
    my $str = shift;
    return undef unless defined ($str); 
  
    $str =~ s/\n/ /g;  # change LF to space
    $str =~ s/\r//g;   # Get rid of CR if any.
    # $str =~ s/<br>//g; # Get rid of HTML <br> if any.
    # $str =~ s/<br \/>//g; # Get rid of HTML <br> if any.
    # $str =~ s/<big>//g; # Get rid of HTML <big> if any.
    # $str =~ s/<\/big>//g; # Get rid of HTML </big> if any.
    # $str =~ s/<BR>//g; # Get rid of HTML <BR> if any.
    # $str =~ s/<B>//g; # Get rid of HTML <B> if any.
    # $str =~ s/<\/B>//g; # Get rid of HTML </B> if any.
    $str =~ s/&nbsp;/ /g; # replace HTML &nbsp if any.
    $str =~ s/<strong>/ /g; # replace HTML &nbsp if any.
    $str =~ s/<\/strong>/ /g; # replace HTML &nbsp if any.

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
    my $programtitle;
    my $previoushref;
    my $t;

    my $p = HTML::PullParser->new(api_version => 3, doc => ${$http->contentRef},
                                  start => 'event, tag, attr,  skipped_text',
                                  end   => 'event, tag, dtext, skipped_text',
                                  report_tags => [qw ( title p a ul li )]);

	$t = getnexttag($p,"title");
	$t = getnexttag($p,"/title");
	$programtitle = $t->[3];
	$programtitle =~ s/NPR.org Text-Only ://; 

	$t = getnexttag($p,"ul");


	while (defined($t =  getnext2tag($p,"li","/ul"))) {
		last if ($t->[1] eq "/ul");
	
		$t = getnexttag($p,"a");
		my $progtitle = $t->[3];
		my $proghref  = $t->[2]->{href};
		$t = getnexttag($p,"/a");
		$progtitle .= 	$t->[3];
#		$log->info("Item title=$progtitle  Item Url=http://thin.npr.org$proghref");
		push @$savedstreams, {
			'name'   => $progtitle,
			'url'    => 'http://thin.npr.org' . $proghref,
			'parser' => 'Plugins::NPRRadio::Parsers::NPRPlayableParser',
			'type'   => 'playlist',
			'on_select'   => 'play',

#			'description' => $progdesc,
			};
	}

#	$log->info(sprintf "found %d streams on page %d/%d of url %s", scalar @$savedstreams,$currentpage,$totalpages,$url);

	# return xmlbrowser hash

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
