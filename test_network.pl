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
# $Id: test_network.pl,v 1.4 2003/08/29 04:03:09 bediger Exp $
# Test all the easy-to-test functions of class Network

use strict;
use diagnostics;

use NWS::Network;
use NWS::Host;


# Test Network code

# 1. Address space size
my ($max_size, $seed) = (50000, 666);
my $network = new Network $max_size, $seed;

if ($network->{max_address} != $max_size) {
	print STDERR "Set $max_size as max address, got back $network->{max_address}\n";
	exit 1;
}

# 2. Random number seed
# 2A. Predetermined
if ($network->GetSeed != $seed) {
	print STDERR "Set $seed as random number seed, got back $network->GetSeed\n";
	exit 2;
}
# 2B. Generated
$network = new Network $max_size, 0;
if ($network->GetSeed == 0) {
	print STDERR "Got back zero as random number seed\n";
	exit 3;
}

# 3. Random address generation
# Note that it uses the generated seed
for (my $idx = 0; $idx < 10000; ++$idx) {
	my $addr = $network->RandAddress;

	if ($addr <= 0) {
		print STDERR 'Got back '. $addr . ' as random address, seed ' . $network->GetSeed . ", size " . $network->{max_address} . "\n";
		exit 4;
	}

	if ($addr > $max_size) {
		print STDERR "Got back random address $addr > $max_size, seed $network->GetSeed, size $network->{max_address}\n";
		exit 5;
	}
}

# 4a. Add a host at a given address, see if it really ends up at that address
$network = new Network $max_size, 0;
my $desired_address = 12;
my $host = new Host 'Linux-x86', $desired_address;
my $addr = $network->AddHost($host);
if ($addr != $desired_address) {
	print STDERR "Added Host at address $desired_address, got back $addr from Network\n";
	exit 6;
}
if ($host->{address} != $desired_address) {
	print STDERR "Added Host at address $desired_address, Host says $host->{address}\n";
	exit 6;
}

# 4b.  Add a host with an address that compares greater-than with the
# address space size.
my $badhost = Host->new('VMS-VAX', $max_size + 1);
my $badaddr = $network->AddHost($badhost);
if ($badaddr != -1) {
	print STDERR "Network with address space of ", $network->{max_address}, ", Host with address " , $max_size + 1, " got added to Network correctly\n";
	exit 6;
}

# 5. Add hosts in a contiguous range, then add hosts at random addresses
# to see if they ever collide.  Only gives partial certainty of correct
# coding, since "random" addresses may never end up in the range.
$network = new Network $max_size, 0;
my $max_used = int $max_size/10;
for (my $idx = 1; $idx <= $max_used; ++$idx) {
	my $h = new Host 'Win2k-x86', $idx;
	my $new_address = $network->AddHost($h);
	if ($new_address != $idx) {
		print STDERR "Added Host at address $idx, got back $new_address from Network\n";
		exit 7;
	}
}

# So we set up an address space of size N.  Then, we added Host instaces
# at addresses 1 to N/10.  Now, we add N/5 hosts randomly. We should get
# 2 collisions if the Network doesn't add hosts randomly correctly.  I think.
for (my $idx = 1; $idx <= 2*$max_used; ++$idx) {
	my $h = new Host 'Solaris-Sparc', 0;
	my $new_address = $network->AddHost($h);
	if ($new_address && $new_address <= $max_used) {
		print STDERR "Added a 2nd host at address $new_address ($max_used added contiguously)\n";
		exit 8;
	}
}

# This program should call all the Network member functions without any
# arguments, and maybe with some incorrect arguments.  Should end up with
# no Perl warnings.

# Undefined address passed to Host::new
my $host_x = new Host 'bozoTclown';
$network->AddHost($host_x);

# Call Network::AddHost w/o a Host
$network->AddHost;

exit 0;
