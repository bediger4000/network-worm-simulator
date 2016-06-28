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
# $Id: msblast.pl,v 1.4 2003/09/07 05:25:20 bediger Exp $
use strict;
use diagnostics;

# Simulate the "Pick an IP address at random, then probe sequentially
# from there" strategy that the August 2003 "msblast.exe" worm uses

use vars qw{$opt_S $opt_A $opt_V $opt_w $opt_s $opt_x $opt_X $opt_h $opt_B};
use Getopt::Std;
use NWS::Network;
use NWS::Message;
use NWS::Host;
use NWS::Software;

my ($seed, $address_space, $victim_cnt, $worm_cnt, $stop_proportion, $banded)
	= (0, 65536, 10000, 1, 0.01, 0);

getopt('S:A:V:B:w:s:');

$seed = $opt_S if $opt_S;
$address_space = $opt_A if $opt_A;
$victim_cnt = $opt_V if $opt_V;
$worm_cnt = $opt_w if $opt_w;  # This doesn't let you set $worm_cnt to 0
$stop_proportion = $opt_s if $opt_s;
$banded = $opt_B if $opt_B;
&usage if $opt_x or $opt_X or $opt_h;

# Proportion of address space that actually has a Host
my $fullness = ($victim_cnt + $worm_cnt)/$address_space;

my $network = new Network $address_space, $seed;

my $msblast_code = q{
	my ($host, $software, $phase, $msg) = @_;
	if ($phase == $Host::Run) {
		$host->SendMsg(
			new Message
				$software->{probe_address},
				"Windows-x86",
				"DCOM",
				$software->{function}
		);
		if (++$software->{probe_address} >= $host->{internet}->{max_address}) {
			$software->{probe_address} = 1;
		}
	} elsif ($phase == $Host::Init2) {
		$software->{true_name} = 'msblast';
		$software->{exploitable} = 0; # msblast can't re-exploit this machine
		$software->{probe_address} = $host->RandAddress;
	} elsif ($phase == $Host::Init) {
		$software->{probe_address} = $host->RandAddress;
	}

};

if ($banded) {
	# This divides the victims into $banded number of strips of addresses,
	# and the strips have a distance of $band_distance between 1st members.
	# The remainder of $victim_cnt/$banded gets put in the final band.
	# This works fine as long as $address_space > $victim_cnt, I think.
	my $vc = $victim_cnt;
	my $per_band = $victim_cnt/$banded;
	my $band_distance = int($address_space/$banded);
	for (my $band = 0; $band < $banded; ++$band) {
		for (my $offset = 1; $offset <= $per_band or $vc < $banded; ++$offset) {
			my $address = $band * $band_distance + $offset;
			my $host2 = new Host 'Windows-x86', $address;
			my $sw3 = new Software 'DCOM', '', 1; # no code, exploitable
			$host2->AddSoftware($sw3);
			$network->AddHost($host2);
			--$vc;
			last if $vc <= 0;
		}
		last if $vc <= 0;
	}
} else {
	for (my $i = 0; $i < $victim_cnt; ++$i) {
		my $host2 = new Host 'Windows-x86', 0;
		my $sw3 = new Software 'DCOM', '', 1; # no code, exploitable
		$host2->AddSoftware($sw3);
		my $addr = $network->AddHost($host2);
	}
}

for (my $i = 0; $i < $worm_cnt; ++$i) {
	my $host = new Host 'Windows-x86', 0;
	my $software = new Software 'msblast', $msblast_code, 0;
	$host->AddSoftware($software);
	my $addr = $network->AddHost($host);
}

my $steps = 135;
my $delta = 5;
print STDERR "Running a Network through $steps time steps\n";

print "# msblast model\n";
if ($banded) {
	print "# Address allocated in $banded bands to victim hosts\n";
} else {
	print "# Random address allocation to hosts\n";
}
print "# Address space size:    $address_space\n";
print "# Starting victim count: ", $victim_cnt, "\n";
print "# Starting worm count:   $worm_cnt\n";
print "# Total entities in population: ", scalar keys %{$network->{hosts}}, "\n";
print "# $steps max, print count every $delta steps\n";
print "# Stop at ", $stop_proportion * 100, "% victims left uninfected\n";
print "# Random address seed:  " . $network->GetSeed . "\n";

my $start_timestamp = time;
$network->PrintCounts;
for (my $i = 1; $i < $steps; $i += $delta ) {
	$network->Run($i, $delta)->PrintCounts;
	last if $network->{software_count}->{DCOM}/$victim_cnt < $stop_proportion;
}
my $stop_timestamp = time;

my $elapsed_time = $stop_timestamp - $start_timestamp;
print "# Elapsed time:          $elapsed_time seconds\n";

# Proportion of Messages that actually hit a Host
my $hitness = $network->{total_hit_count}/$network->{total_msg_count};

print "# Total count of messages: $network->{total_msg_count}\n";
print "# Total of messages that hit a Host: $network->{total_hit_count}\n";
print "# Proportion of address space filled: $fullness\n";
print "# Proportion of messages that hit:    $hitness\n";

sub numerically {$a<=>$b};

foreach my $address (sort numerically keys %{$network->{hosts}}) {
	my $host = $network->{hosts}->{$address};
	print "#hits\t", $address, "\t", $host->{msg_cnt}->{rcvd}, "\n";
}

exit 0;

sub usage
{
	print "$0: msblast network worm model\n";
	print "Options:   -S seed    set PRNG seed (default set randomly)\n";
	print "           -A size    set address space size (default 65535)\n";
	print "           -V number  set number of victim hosts (default 9999)\n";
	print "           -w number  set initial number of worm hosts (default 1)\n";
	print "           -s number  set proportion of remaining victim hosts to stop at (default 0.01)\n";
	exit 0;
}
