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
# $Id: wormfight3.pl,v 1.3 2003/08/29 04:03:09 bediger Exp $
use strict;
use diagnostics;

use NWS::Network;
use NWS::Host;
use NWS::Message;
use NWS::Software;

my $seed;

# Worm code - should compare identically except for the "true name",
# and Code Red II marks its software as not exploitable.
my $cr1v2_code = q{
	my ($host, $software, $code, $msg) = @_;
	if ($code == $Host::Run) {
		$host->SendMsg(
			new Message
				$host->RandAddress,
				"Windows-x86",
				"IIS",
				$software->{function}
		);
	} elsif ($code == $Host::Init2) {
		$software->{true_name} = 'Code Red I v2';
	}
};
my $cr2_code = q{
	my ($host, $software, $code, $msg) = @_;
	if ($code == $Host::Run) {
		$host->SendMsg(
			new Message
				$host->RandAddress,
				"Windows-x86",
				"IIS",
				$software->{function}
		);
	} elsif ($code == $Host::Init2) {
		$software->{exploitable} = 0; # Key difference from $cr1v2_code above
		$software->{true_name} = 'Code Red II';
	}
};

print "# Worm fight - two worms compete for hosts that allow the same\n";
print "# exploit.  One worm fixes the exploit on infection.\n";

$seed = $ARGV[0] if $ARGV[0];

my ($address_space, $victim_cnt)
	= (65535, 10000);

my $network = new Network $address_space, $seed;

# Parameterizing the number of each worm at the start doesn't make sense.
# Which worm predominates at the end makes up the whole point of this simulation.
my $host1 = new Host 'Windows-x86', 10;
my $software1 = new Software 'Code Red I v2', $cr1v2_code, 1;
$host1->AddSoftware($software1);

my $host2 = new Host 'Windows-x86', $address_space - 10;
my $software2 = new Software 'Code Red II', $cr2_code, 0;  # Not exploitable
$host2->AddSoftware($software2);

# Does the order of this make any difference?
# Yes - if the Network always calls Host::RunProcesses on one of them
# before the other one consistently.
my $addr2 = $network->AddHost($host2);
my $addr1 = $network->AddHost($host1);
print "# " . $software1->{identifier} . " at address " . $host1->{address} . "\n";
print "# " . $software2->{identifier} . " at address " . $host2->{address} . "\n";

for (my $i = 1; $i < $victim_cnt; ++$i) {
	my $host2 = new Host 'Windows-x86', 0;
	my $sw3 = new Software 'IIS', '', 1; # exploitable
	$host2->AddSoftware($sw3);
	my $addr = $network->AddHost($host2);
}

my $steps = 100;
my $delta = 5;
print STDERR "Running a Network through $steps time steps\n";
print "# Random address seed: " . $network->GetSeed . "\n";
print "# Address space $address_space in size\n";
print "# $victim_cnt infectible hosts originally\n";
print "# Executing $steps time steps, print counts every $delta steps\n";
print "# Runs a fixed number of steps rather than stopping at some\n";
print "# remaining percentage of victims to see what the worms do to each other.\n";
my $start_timestamp = time;
$network->PrintCounts;
for (my $i = 1; $i < $steps; $i += $delta) {
	$network->Run($i, $delta)->PrintCounts;
}
my $stop_timestamp = time;
my $elapsed_time = $stop_timestamp - $start_timestamp;
print "# Elapsed time:          $elapsed_time seconds\n";

# Print out final counts some identifiable way
my $x = $network->{software_count};
print "# Final 'Code Red I v2': ", $x->{"Code Red I v2"}, "\n";
print "# Final 'Code Red II': ", $x->{"Code Red II"}, "\n";

exit 0;
