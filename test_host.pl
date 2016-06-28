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
# $Id: test_host.pl,v 1.4 2003/08/29 04:03:09 bediger Exp $
# Test all of the easy-to-test Host functions
use strict;
use diagnostics;

use NWS::Host;
use NWS::Software;
use NWS::Network;
use NWS::Message;


my $identifier = 'Solaris-x86';
my $testcode = q{
	my ($code, $msg) = @_;
};

# Check creation with and without address,
# with and without Software.  Matrix of 4 items.
my $ware = new Software 'Test Software', $testcode, 1;
my @address = (2701);
my @software = ($ware);
for (my $i = 0; $i < 2; ++$i) {
	for (my $j = 0; $j < 2; ++$j) {
		my $host = new Host $identifier, $address[$i];
		$host->AddSoftware($software[$j]);
		if ($address[$i]) {
			if (!$host->{address} or $host->{address} != $address[$i]) {
				print STDERR "($i, $j) Host address set in constructor call, not set in Host instance\n";
				exit 1;
			}
		} else {
			if ($host->{address}) {
				print STDERR "($i, $j) Host address of \"$host->{address}\" not set in constructor call\n";
				exit 2;
			}
		}
		my $n = scalar @{$host->{software_array}};
		if ($software[$j]) {
			if ($n != 1) {
				print STDERR "($i, $j) Software set in constructor call, not set in Host instance\n";
				exit 3;
			}
		} else {
			if ($n != 0) {
				print STDERR "($i, $j) Software not set in constructor call, set in Host instance\n";
				exit 4;
			}
		}
	}
}

# Check addition of Software.
#   Add software, lookup up in software dictionary, check index in software array
my $host = new Host $identifier, 722;
$host->AddSoftware();
$host->AddSoftware($ware);
my $sw = $host->{software_dict}->{$ware->{identifier}};
if (! $sw || $sw != $ware) {
	print STDERR "Did not lookup software by name in new Host\n";
	exit 4;
}

my $idx = 0;
my $err_exit = 0;
for my $w (@{$host->{software_array}}) {
	if ($w->{identifier} eq $ware->{identifier} && $idx != 0) {
		print STDERR "Did not find software at index 0\n";
		$err_exit = 1;
	}
	++$idx;
}
if ($err_exit) {
	exit 5;
}

# Check removal of Software.
$host->RemoveSoftware();  # Should not generate a run-time warning
$host->RemoveSoftware($ware->{identifier});
for my $w (@{$host->{software_array}}) {
	if ($w->{identifier} eq $ware->{identifier}) {
		print STDERR "Found software $ware->{identifier} in Host instance after removal\n";
		exit 6;
	}
}

# Goofy calls to Host::TimeStep and Host::RandAddress won't produce errors
# detectable by checking return value, just warnings from the Perl interpreter.
# Check timestep w/o Host as element of Network
my $ts = $host->TimeStep;
# Check random address generatio w/o Host as element of Network
my $addr = $host->RandAddress;
my $network = new Network 10000, 0;
$network->AddHost($host);
$ts = $host->TimeStep;
$addr = $host->RandAddress;

# Check reception of a message sent by self w/o Host as part of Network
$host = new Host $identifier;
$host->AddSoftware($ware);
my $msg = new Message $host->{address}, $host->{identifier},
	$host->{software_array}->[0]->{identifier}, '';
$host->SendMsg($msg);  # should not produce error message

# Add Host to Network, re-try message reception
# Host has to belong to a Network for message sending to work
$network = new Network 10000, 0;
my $cnt_host = new Host $identifier, 0,
	(new Software 'Code Red', $testcode, 0);
$network->AddHost($cnt_host);

my $msg2 = new Message $cnt_host->{address}, $cnt_host->{identifier},
	$cnt_host->{software_array}->[0]->{identifier}, '';

$cnt_host->SendMsg($msg2);

# Send another message, check that sequence number gets incremented
my $msg3 = new Message $cnt_host->{address}, $cnt_host->{identifier},
	$cnt_host->{software_array}->[0]->{identifier}, '';
$cnt_host->SendMsg($msg3);

if ($msg3->{sequence} != ($msg2->{sequence} + 1)) {
	print STDERR "First message sequence no. " . $msg2->{sequence} . "\n";
	print STDERR "Second message sequence no. " . $msg3->{sequence} . "\n";
	print STDERR "Not off by one\n";
}

# Check sending a message to another host
# Check reception of a message by another host
# See message_delivery.pl

exit 0;
