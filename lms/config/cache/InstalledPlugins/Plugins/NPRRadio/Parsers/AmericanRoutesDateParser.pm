#
#
# This program is free software; you can redistribute it and/or 
# modify it under the terms of the GNU General Public License, version 2.
#
#
package Plugins::NPRRadio::Parsers::AmericanRoutesDateParser;

use strict;

use Slim::Utils::Log;

use HTML::PullParser;

my $log = logger('plugin.nprradio');

sub parse
{
    my $class  = shift;
    my $http   = shift;

    my $params = $http->params('params');
    my $url    = $params->{'url'};
    my $client = $params->{client};

    $log->debug('Begin');
    my $dateurl = 'http://americanroutes.publicradio.org/archives/for_date/' . $params->{'item'}->{'name'} ;

	return {
		'type'  => 'opml',
		'name'  => "American routes - ".  $params->{'item'}->{'name'},
		'items' => [
			{
			  'name' => 'January',
			  'url'  => $dateurl . '-1',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
			{
			  'name' => 'February',
			  'url'  => $dateurl . '-2',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
			{
			  'name' => 'March',
			  'url'  => $dateurl . '-3',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
			{
			  'name' => 'April',
			  'url'  => $dateurl . '-4',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
			{
			  'name' => 'May',
			  'url'  => $dateurl . '-5',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
			{
			  'name' => 'June',
			  'url'  => $dateurl . '-6',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
			{
			  'name' => 'July',
			  'url'  => $dateurl . '-7',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
			{
			  'name' => 'August',
			  'url'  => $dateurl . '-8',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
			{
			  'name' => 'September',
			  'url'  => $dateurl . '-9',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
			{
			  'name' => 'October',
			  'url'  => $dateurl . '-10',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
			{
			  'name' => 'November',
			  'url'  => $dateurl . '-11',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
			{
			  'name' => 'December',
			  'url'  => $dateurl . '-12',
			  'parser' => 'Plugins::NPRRadio::Parsers::AmericanRoutesDateProgParser',
			},
		],
	};

}
# Local Variables:
# tab-width:4
# indent-tabs-mode:t
# End:

1;
