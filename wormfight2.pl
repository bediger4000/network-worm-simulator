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
# $Id: wormfight2.pl,v 1.4 2003/08/29 04:03:09 bediger Exp $
use strict;
use diagnostics;

$main::default_seed = 0;
$main::default_address_space = 65535, 
$main::default_victim_cnt = 10000;
$main::default_cr1v2_cnt = 7;
$main::default_cr2_cnt = 7;
$main::default_virulence = 1;

use vars qw{$opt_S $opt_A $opt_V $opt_v $opt_c $opt_C $opt_x $opt_X $opt_h};
use Getopt::Std;
use NWS::Network;
use NWS::Host;
use NWS::Message;
use NWS::Software;

my ($seed, $address_space, $victim_cnt, $cr1v2_cnt, $cr2_cnt)
	= ($main::default_seed, $main::default_address_space,
		$main::default_victim_cnt, $main::default_cr1v2_cnt,
		$main::default_cr2_cnt);

$main::virulence = $main::default_virulence;

getopt('S:A:V:v:c:C:');

$seed            = $opt_S if $opt_S;
$address_space   = $opt_A if $opt_A;
$victim_cnt      = $opt_V if $opt_V;
$main::virulence = $opt_v if $opt_v;
$cr1v2_cnt       = $opt_c if $opt_c;
$cr2_cnt         = $opt_C if $opt_C;
&usage if $opt_x or $opt_X or $opt_h;

# Generic, random-address probe worm, arbitrarily designated "Code Red 1, v2"
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

# About X% of the time steps ($main::virulence), this worm sends 2 probes
# to random addresses.  Arbitrarily designated "Code Red II" for verisimilitude.
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
		if (int(rand 100) < $main::virulence) {
			$host->SendMsg(
				new Message
					$host->RandAddress,
					"Windows-x86",
					"IIS",
					$software->{function}
			);
		}
	} elsif ($code == $Host::Init2) {
		$software->{true_name} = 'Code Red II';
	}
};

print "# Worm fight - two worms compete for hosts that allow the same\n";
print "# exploit.  Neither worm fixes the exploit.\n";
print "# The worm designated 'Code Red II' sends 2 messages $main::virulence% of the times it runs.\n";
print "# This should test what a slight advantage does to infection rates.\n";
print "# A slight advantage in infection might explain why the real CRII\n";
print "# beat out CR1v2 during CRII's alloted span.\n";

my $network = new Network $address_space, $seed;

# Parameterizing the number of each worm at the start doesn't make sense.
# Which worm predominates at the end makes up the whole point of this simulation.
for (my $i = 0; $i < 7; ++$i) {
	my $host1 = new Host 'Windows-x86', 0;
	my $software1 = new Software 'Code Red I v2', $cr1v2_code, 1;
	$host1->AddSoftware($software1);
	my $addr = $network->AddHost($host1);
}

for (my $i = 0; $i < 7; ++$i) {
	my $host2 = new Host 'Windows-x86', 0;
	my $software2 = new Software 'Code Red II', $cr2_code, 1;
	$host2->AddSoftware($software2);
	my $addr = $network->AddHost($host2);
}

# Does the order of this make any difference?
# Yes - if the Network always calls Host::RunProcesses on one of them
# before the other one consistently.
#my $addr2 = $network->AddHost($host2);
#my $addr1 = $network->AddHost($host1);
#print "# " . $software1->{identifier} . " at address " . $host1->{address} . "\n";
#print "# " . $software2->{identifier} . " at address " . $host2->{address} . "\n";
print "# 7 each of two competing worms\n";

for (my $i = 1; $i < $victim_cnt; ++$i) {
	my $host2 = new Host 'Windows-x86', 0;
	my $sw3 = new Software 'IIS', '', 1; # exploitable
	$host2->AddSoftware($sw3);
	my $addr = $network->AddHost($host2);
}

my $steps = 150;
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
print "# Final 'Code Red I v2': ", $x->{"Code Red I v2"}? $x->{"Code Red I v2"}:0, "\n";
print "# Final 'Code Red II': ", $x->{"Code Red II"}? $x->{"Code Red II"}: 0, "\n";

exit 0;

sub usage
{
	print "$0: Competing worms of different virulence simuation\n";
	print "Options:   -S seed    set PRNG seed (default set randomly)\n";
	print "           -A size    set address space size (default $main::default_address_space)\n";
	print "           -V number  set number of victim hosts (default $main::default_victim_cnt)\n";
	print "           -v number  set extra CRII probe attempts percentage (default $main::default_virulence%)\n";
	print "           -c number  set number of Code Red I v2 hosts (default $main::default_cr1v2_cnt)\n";
	print "           -C number  set number of Code Red II hosts (default $main::default_cr2_cnt)\n";
	exit 0;
}
