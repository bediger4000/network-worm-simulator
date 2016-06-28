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
# $Id: worm_execution.pl,v 1.3 2003/08/29 04:03:09 bediger Exp $
use strict;
use diagnostics;

use NWS::Network;
use NWS::Host;
use NWS::Message;
use NWS::Software;

# Ensure that all 4 phases get executed or not, as appropriate
$main::run_executed = 0;
$main::init_executed = 0;
$main::init2_executed = 0;
$main::recv_executed = 0;
$main::message_received = 0;

my $phase_code = q{
	my ($host, $software, $phase, $msg) = @_;
	if (!$host) {
		print STDERR "No NWS::Host reference passed to function\n";
	}
	if (!$software) {
		print STDERR "No NWS::Software reference passed to function\n";
	}
	if ($phase == $Host::Run) {
		++$main::run_executed;
	} elsif ($phase == $Host::Init) {
		++$main::init_executed;
	} elsif ($phase == $Host::Init2) {
		# Only runs this case on exploitation.
		++$main::init2_executed;
	} elsif ($phase == $Host::Recv) {
		++$main::recv_executed;
		++$main::message_received if $msg;
	}
};

my $host = Host->new('OS-CPU', 0, Software->new('Software', $phase_code, 0));
if (!$main::init_executed) {
	print STDERR "Host::AddSoftware did not call worm code appropriately\n";
	exit 1;
}
my $network = Network->new(100, 0);
my $addr = $network->AddHost($host);

$network->Run(0, 1);
if (!$main::run_executed) {
	print STDERR "Host::RunProcess did not call worm code appropriately\n";
	exit 1;
}
# Send the NWS::Host a Message to trigger $Host::Recv phase.
$network->AcceptMsg(
	Message->new(
		$addr,
		'OS-CPU',
		'Software',
		'print STDERR "Should not see this\n";'
	)
);
# Run one more timestep to get Message delivered to Host
$network->Run(1, 1);

my $exit_code = 0;

if (!$main::run_executed) {
	print STDERR "Did not execute worm code in course of Network::Run\n";
	++$exit_code;
}

if (!$main::init_executed) {
	print STDERR "Did not execute worm code in course of Host::AddSoftware\n";
	++$exit_code;
}

# This test expects to *not* have executed this phase.
if ($main::init2_executed) {
	print STDERR "Erroneously executed worm code in context of explotation\n";
	++$exit_code;
}

if (!$main::recv_executed) {
	print STDERR "Did not execute worm code in context of message reception\n";
	++$exit_code;
} else {
	if (!$main::message_received) {
		print STDERR "Host::Recv phase encountered, but got no Message\n";
		++$exit_code;
	}
}

exit $exit_code;
