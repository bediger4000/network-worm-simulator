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
# $Id: addr_space_end.pl,v 1.6 2003/08/29 04:03:09 bediger Exp $
use strict;
use diagnostics;

use NWS::Network;
use NWS::Host;
use NWS::Message;
use NWS::Software;

my $seed;

my $sender_code = q{
	my ($host, $software, $phase) = @_;
	if ($phase == $Host::Run) {
		$host->SendMsg(
			Message->new(
				$main::receiver_address,
				'OS-CPU',
				'Receiver',
				''
			)
		);
	}
};

# $rcvr_code pushes all the source addres of NWS::Message objects
# it receives on this list.
@main::reception = ();

my $rcvr_code = q{
	my ($host, $software, $phase, $msg) = @_;
	if ($phase == $Host::Recv) {
		if ($msg) {
			push @main::reception, $msg->{source};
		} else {
			print STDERR "Recv code, no msg\n";
		}
	}
};

$seed = $ARGV[0] if $ARGV[0];

my $address_space = 65535;

$main::receiver_address = 32768;

my $network = new Network $address_space, $seed;


# Receiver host lives at midpoint of address space
my $host1 = new Host 'OS-CPU', $main::receiver_address;
my $software1 = new Software 'Receiver', $rcvr_code, 0;
$host1->AddSoftware($software1);
my $addr = $network->AddHost($host1);
if ($addr != $main::receiver_address) {
	# Network::AddHost hosed up placing receiver host
	print STDERR "NWS::Network placed receiver Host at " . $addr
		. ", should have placed it at " . $main::receiver_address . "\n";
	exit 1;
}

# One sender host lives at address 65535 - 10, the other end of the address space.
my $host2 = new Host 'OS-CPU', $address_space - 10;
my $software2 = new Software 'Sender', $sender_code, 0;
$host2->AddSoftware($software2);

my $host3 = new Host 'OS-CPU', 10;
my $software3 = new Software 'Sender', $sender_code, 0;
$host3->AddSoftware($software3);

# Does the order of the worms in the address space make any difference?
# Yes - if the Network object calls Host::RunProcesses on one of them
# before the other one consistently, or delivers the messages they
# send with some preference to one or the other.
my $addr2 = $network->AddHost($host2);
my $addr3 = $network->AddHost($host3);
print "# " . $software1->{identifier} . " at address " . $host1->{address} . "\n";
print "# " . $software2->{identifier} . " at address " . $host2->{address} . "\n";
print "# " . $software3->{identifier} . " at address " . $host3->{address} . "\n";
print "# " . "Receiver supposedly at: " . $main::receiver_address . "\n";

my $steps = 8000;
print STDERR "Running a Network through $steps time steps\n";
print "# Random address seed: " . $network->GetSeed . "\n";
print "# Address space $address_space in size\n";
print "# Executing $steps time steps\n";
print "# Runs a fixed number of steps rather than stopping at some\n";
print "# remaining percentage of victims to see what the worms do to each other.\n";
my $start_timestamp = time;
$network->Run(1, $steps)->PrintCounts;
my $stop_timestamp = time;
my $elapsed_time = $stop_timestamp - $start_timestamp;
print "# Elapsed time:          $elapsed_time seconds\n";

my $parity = 0;
my $hi_addr_msg_cnt = 0;
my $lo_addr_msg_cnt = 0;
my $hi = 0;
my $lo = 0;

my $n = scalar @main::reception;
print "Total messages received: ", $n, "\n";
if ($n != 2*$steps) {
	# This also catches any off-by-one problems, since 2*$steps is even.
	print STDERR "Not enough messages received, should have gotten ", 2*$steps, "\n";
	exit 3;
}

foreach my $addr (@main::reception) {
	if ($addr < $address_space/2) {
		$lo += $parity;
		++$lo_addr_msg_cnt;
	} else {
		$hi += $parity;
		++$hi_addr_msg_cnt;
	}
	$parity ^= 1;
}

print "Hi address source messsages: ", $hi_addr_msg_cnt, "\n";
print "Lo address source messsages: ", $lo_addr_msg_cnt, "\n";

if ($hi_addr_msg_cnt != $lo_addr_msg_cnt) {
	print STDERR "Got $hi_addr_msg_cnt messages from hi address, $lo_addr_msg_cnt from low address\n";
	exit (4);
}

$lo /= $lo_addr_msg_cnt;
$hi /= $hi_addr_msg_cnt;

print "High address score: ", $hi, "\n";
print "Low  address score: ", $lo, "\n";

if (abs($lo - $hi) > .02) {
	print STDERR "Problem with message reception related to position in address space\n";
	exit 5;
}

exit 0;
