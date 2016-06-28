#!/usr/bin/perl
# Copyright 2003, Bruce Ediger
# This file is part of NWS.
#
# NWS is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# NWS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with NWS; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
use NWS::Network;
use NWS::Message;
use NWS::Host;
use NWS::Software;

my $worm_code = q{
	my ($host, $software, $phase) = @_;
	$host->SendMsg(
		Message->new(
			$host->RandAddress,
			'OS-CPU',
			'Victim',
			$software->{function})
	) if $phase == $Host::Run;
	$software->{true_name} = 'Worm' if $phase == $Host::Init2;
};

my $network = Network->new(65535, 0);
$network->AddHost(Host->new('OS-CPU', 0, Software->new('Worm', $worm_code, 0)));
$network->AddHost(Host->new('OS-CPU', 0, Software->new('Victim', '', 1)))
	for (1..10000);

for (my $i = 1; $i < 135; $i += 5) {
	$network->Run($i, 5)->PrintCounts;
}

exit 0;
