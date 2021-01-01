#
#
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License, version 2.
#
#
package Plugins::NPRRadio::Parsers::NPRPlayAllParser;

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
  }
}

use Data::Dumper;
sub parse
{
    my $class  = shift;
    my $http   = shift;

    my $params = $http->params('params');
    my $url    = $params->{'url'};
    my $client = $params->{client};
    my $savedstreams;
    my $programtitle;
    my $programhref;
    my $programdesc;
    my $t;
    my $itemslist = $client->pluginData('nprplayall');
    my $playlist = $params->{'nprplaylist'};

        my $p = HTML::PullParser->new(api_version => 3, doc => ${$http->contentRef},
                                  start => 'event, tag, attr,  skipped_text',
                                  end   => 'event, tag, dtext, skipped_text',
                                  report_tags => [qw ( title p a )]);

	$t = getnexttag($p,"title");
	$t = getnexttag($p,"/title");
	$programtitle = $t->[3];


	$t = getnexttag($p,"/p");
	$t = getnexttag($p,"/p");

	$t = getnexttag($p,"p");
	$t = getnexttag($p,"a");
	return undef if (!defined($t));

	$programhref = (defined($t->[2]->{href})) ? $t->[2]->{href} : undef;
	$t = getnexttag($p,"/a");
	return undef unless ($t->[3] =~ m/LISTEN: / );
	$programtitle = $t->[3];
	$programtitle =~ s/LISTEN: //;

	$t = getnexttag($p,"p");
	$t = getnexttag($p,"/p");
	$programdesc = $t->[3];
	if ($programdesc =~ m/^By /) {
		$t = getnexttag($p,"p");
		$t = getnexttag($p,"/p");
		$programdesc .= " " . $t->[3];
	} 

	$log->debug( "Prog text = \'$programtitle\' URL=$programhref");

	push @$playlist, {
			'name' => $programtitle,
			'url'  => 'http://thin.npr.org' . $programhref,
			'description' => $programdesc,
			'type' => 'audio',
			'icon' => Plugins::NPRRadio::Plugin->_pluginDataFor('icon'),
	};

	my $nextitem = shift @$itemslist;
	if (defined($nextitem) ) {
	        $params->{'nprplaylist' => \@$itemslist};
		$params->{'nprplaylist'} = $playlist;

		return {
			'type' => 'redirect',
			'url'  => $nextitem
		};
	} 

	return {
		'name' => "Play all",
		'type'  => 'playlist',
		'items' => \@$playlist,
		'on_select'   => 'play',

	};
	
}
# Local Variables:
# tab-width:4
# indent-tabs-mode:t
# End:

1;
