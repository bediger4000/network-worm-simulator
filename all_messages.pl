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
# $Id: all_messages.pl,v 1.2 2003/09/21 19:18:29 bediger Exp $
use strict;
use diagnostics;

use vars qw{$opt_S $opt_A $opt_V $opt_w $opt_s $opt_x $opt_X $opt_h $opt_B};
use Getopt::Std;
use NWS::Network;
use NWS::Message;
use NWS::Host;
use NWS::Software;

my ($seed, $address_space, $victim_cnt, $worm_cnt, $stop_proportion)
	= (0, 65536, 10000, 1, 0.01);

getopt('S:A:V:w:s:');

$seed = $opt_S if $opt_S;
$address_space = $opt_A if $opt_A;
$victim_cnt = $opt_V if $opt_V;
$worm_cnt = $opt_w if $opt_w;
$stop_proportion = $opt_s if $opt_s;
&usage if $opt_x or $opt_X or $opt_h;

# Proportion of address space that actually has a Host
my $fullness = ($victim_cnt + $worm_cnt)/$address_space;

my $network = new Network $address_space, $seed;

# The following worm code tries to trigger bugs in message
# delivery.  All Messge objects should get delivered by the
# end of a timestep.  For buggy message delivery algorithms,
# a Message sent after the call to Host->Run (if a "cleaner"
# worm responded to a probe, for example) wouldn't get delivered
# until the next time step.  By blind luck, the following worm
# should get all cases:
# 1. Worm runs, then gets infection message from another worm,
#    causing a responce to the other worm.
# 2. Worm gets infection message from another worm, to which
#    it resonds, then it runs later.
# Position in address space may have something to do with it,
# too, but blind luck should get us those cases too.
#
# This code also has a little interest since it resembles
# the permutation scanning worm a little bit - upon probing
# an already-infected address, individual worms go inactive.
# Some fraction of the population "going inactive" changes
# the behavior of the simulation quite radically.  Just as
# the population goes epidemic, the number of inactive individuals
# goes way up.  This might constitue a way to create a population
# of zombies - humans watching for infections will see them all
# stop, about as quickly as they were arriving.  The inactive
# worms can just wait for commands, similar to the PUD network(s)
# set up by Slapper variants.
my $Aworm_code = q{
	my ($host, $software, $phase, $msg) = @_;
	if ($phase == $Host::Run && $software->{active}) {
		$host->SendMsg(
			new Message
				$host->RandAddress,
				"OS-CPU",
				"Bvictim",
				$software->{function}
		);
	} elsif ($phase == $Host::Recv) {
		if (!$msg->{agent99}) {
			$msg->{destination} = $msg->{source};
			$msg->{agent99} = $host->{address};
			$msg->{code} = 0;
			$host->SendMsg($msg);
		} else {
			$software->{true_name} = 'Aworm - inactive';
			$software->{active} = 0;
		}
	} elsif ($phase == $Host::Init2 || $phase == $Host::Init) {
		$software->{true_name} = 'Aworm - active';
		$software->{exploitable} = 0; # Aworm can't re-exploit this machine
		$software->{active} = 1;
	}
};

for (my $i = 0; $i < $victim_cnt; ++$i) {
	my $host2 = new Host 'OS-CPU', 0;
	my $sw3 = new Software 'Bvictim', '', 1; # no code, exploitable
	$host2->AddSoftware($sw3);
	my $addr = $network->AddHost($host2);
}

for (my $i = 0; $i < $worm_cnt; ++$i) {
	my $host = new Host 'OS-CPU', 0;
	my $software = new Software 'Aworm', $Aworm_code, 0;
	$host->AddSoftware($software);
	my $addr = $network->AddHost($host);
}

my $placekeeper = new Host 'OS-CPU', 0;
my $pk_software = new Software 'Aworm - inactive', '', 0;
$placekeeper->AddSoftware($pk_software);
$network->AddHost($placekeeper);


my $steps = 200;
my $delta = 1;

print "# Generic SIS model with no disinfection.\n";
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
	my $n = scalar @{$network->{msg_queue}};
	if ($n > 0) {
		print STDERR "# Network had $n messages in its queue after a timestep\n";
		exit 1;
	}
	last if $network->{software_count}->{Bvictim}/$victim_cnt < $stop_proportion;
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
	print "$0: Susceptible-Infected-Susceptible network worm model\n";
	print "Options:   -S seed    set PRNG seed (default set randomly)\n";
	print "           -A size    set address space size (default 65535)\n";
	print "           -V number  set number of victim hosts (default 9999)\n";
	print "           -w number  set initial number of worm hosts (default 1)\n";
	print "           -s number  set proportion of remaining victim hosts to stop at (default 0.01)\n";
	exit 0;
}
