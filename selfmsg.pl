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
# $Id: selfmsg.pl,v 1.5 2003/08/29 04:03:09 bediger Exp $
use strict;
use diagnostics;

# selfmsg.pl - Software that sends a message to itself.
# Tests the messsage-to-self shortcut code.

# A given Software can get executed on 4 different occasions:
# 1. When it gets "installed" (in Host::AddSoftware)
# 2. Should it get "installed" from a Message recption (in Host::RecvMsg)
# 3. When it actually receives a Message (again, in Host::RecvMsg)
# 4. When it gets executed (in Host::RunProcesses)
#
# Arguments to the function in the Sofware differ according to the 4
# situations:
# 1 - $Host::Init
# 2 - $Host::Init2
# 3 - $Host::Recv, $msg  (2 arguments)
# 4 - $Host::Run

use NWS::Host;
use NWS::Message;
use NWS::Software;
use NWS::Network;

my $seed;

$seed = $ARGV[0] if $ARGV[0];

$main::sent_msg           = 0;
$main::received_msg       = 0;
$main::received_from_self = 0;
$main::install_init       = 0;
$main::exploit_init       = 0;  # remains 0

my $code = q{
	my ($host, $software, $code, $msg) = @_;
	if ($code == $Host::Run) {
		if ($host->TimeStep == 4) {
			++$main::sent_msg;
			$host->SendMsg(
				Message->new($host->{address}, $host->{identifier}, $software->{identifier}, '')
			);
		}
	} elsif ($code == $Host::Recv) {
		# Just got a Message, hopefully from itself
		++$main::received_msg;
		++$main::received_from_self if $msg->{source} == $host->{address};
	} elsif ($code == $Host::Init) {
		++$main::install_init;
	} elsif ($code == $Host::Init2) {
		++$main::exploit_init;
	}
};

my $network = new Network 50000, $seed;
my $selfmsghost = new Host 'Linux-x86', 10;
my $software = new Software 'SelfMsg', $code, 0;
$selfmsghost->AddSoftware($software);
$network->AddHost($selfmsghost);

my $steps = 10;
$network->Run(1, $steps);

my $errcnt = 0;

if ($main::sent_msg == 0) {
	print STDERR "Did not send a Message\n";
	++$errcnt;
}
if ($main::received_msg == 0) {
	print STDERR "Did not receive a Message\n";
	++$errcnt;
}
if ($main::received_from_self == 0) {
	print STDERR "Did not receive a Message from self\n";
	++$errcnt;
}
if ($main::install_init == 0) {
	print STDERR "Did not get initialized at installation\n";
	++$errcnt;
}
if ($main::exploit_init != 0) {
	print STDERR "Incorrectly initialized at exploitation\n";
	++$errcnt;
}

my $addr = $selfmsghost->{address};

if ($selfmsghost->{msg_cnt}->{rcvd} != 1) {
	print STDERR "Host at $addr received " . $selfmsghost->{msg_cnt}->{rcvd} . " messages (should be 1)\n";
	++$errcnt;
}
if ($selfmsghost->{msg_cnt}->{matched} != 1) {
	print STDERR "Host at $addr matched " . $selfmsghost->{msg_cnt}->{matched} . " messages (should be 1)\n";
	++$errcnt;
}
if ($selfmsghost->{msg_cnt}->{accepted} != 1) {
	print STDERR "Host at $addr accepted " . $selfmsghost->{msg_cnt}->{accepted} . " messages (should be 1)\n";
	++$errcnt;
}
if ($selfmsghost->{msg_cnt}->{exploited} != 0) {
	print STDERR "Host at $addr got exploited by " . $selfmsghost->{msg_cnt}->{exploited} . " messages (should be 0)\n";
	++$errcnt;
}

if ($network->{total_msg_count} != 1) {
	print STDERR "Network delivered ", $network->{total_msg_count}, " messages total (should be 1)\n";
	++$errcnt;
}
if ($network->{total_hit_count} != 1) {
	print STDERR "Network delivered ", $network->{total_hit_count}, " messages that hit a host (should be 1)\n";
	++$errcnt;
}

print STDERR "Seed: ", $seed, "\n" if $errcnt;

exit $errcnt;
