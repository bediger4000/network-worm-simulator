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
# $Id: message_delivery.pl,v 1.5 2003/08/29 04:03:09 bediger Exp $
# Test message delivery: reliability and order of delivery.

use strict;
use diagnostics;

use NWS::Network;
use NWS::Host;
use NWS::Message;
use NWS::Software;

@main::sequence = ();
$main::max = 99;
$main::Max = $main::max + 1;

# This code sends $main::Max Messages to address 334, which hopefully
# holds a host with "msgrcv" software.
my $msg_snd = q{
	my ($host, $software, $code, $msg) = @_;
	if ($code == $Host::Run) {
		$host->SendMsg(Message->new(334, 'Message Receiver', 'msgrcv', ''))
			foreach (0..$main::max);
	}
};

# Code for "msgrcv" software - just push the sequence number onto
# a well-known array, for examination later.
my $msg_rcv = q{
	my ($host, $software, $code, $msg) = @_;
	push @main::sequence, $msg->{sequence} if $code == $Host::Recv;
};

my $ntwk = Network->new(63501, 0);
$ntwk->AddHost(Host->new('Message Receiver', 334, Software->new('msgrcv', $msg_rcv, 0)));
$ntwk->AddHost(Host->new('Message Sender',     0, Software->new('msgsnd', $msg_snd, 0)));

$ntwk->Run(0, 1);

# Check that all Messages got received, none dropped.
my $l = scalar @main::sequence;
if ($l != $main::Max) {
	print STDERR "Sent $main::Max messages, received $l\n";
	exit 1;
}

# Check to see if any sequence numbers between 0..$main::max got dropped.
sub numerically {$a<=>$b;}
my @in_order = sort numerically @main::sequence;
foreach my $i (0..$main::max) {
	if ($in_order[$i] != $i) {
		print STDERR "Missing sequence number $i\n";
		exit 2;
	}
}

# This calculates a "Hamming distance" for the
# elements of the array compared to the index of the elements.
my $in_order_cnt = 0;
my $x = 0;
foreach my $sequence_number (@main::sequence) {
	++$in_order_cnt if $sequence_number == $x;
	++$x;
}

# This seems like the hard part - how do you decide how many
# messages with sequence numbers that actually end up in
# sequence means that the message delivery stuff is screwed?
if ($in_order_cnt > int(.05*$main::Max)) {
	print STDERR "Found $in_order_cnt in-order messages out of $x\n";
	exit 3;
}


exit 0;
