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
# $Id: removetest.pl,v 1.6 2003/08/29 04:03:09 bediger Exp $
# Test removal of Software instances from a Host instance
use strict;
use diagnostics;

use NWS::Network;
use NWS::Host;
use NWS::Software;
use NWS::Message;

my $seed;

if ($ARGV[0]) {
	$seed = $ARGV[0];
}

$main::tried_removal    = 0;
$main::sent_message     = 0;
$main::software_existed = 0;
$main::received_message = 0;

my $internet = new Network 50000, $seed;

# ping host lives at address 10
my $pinghost = new Host 'Linux-x86', 10;

my $software = new Software 'Ping',
q{
	my ($host, $software, $code, $msg) = @_;
	if ($code == $Host::Run) {
		if ($host->TimeStep == 4) {
			++$main::tried_removal;
			$host->RemoveSoftware('Clodhopper');
		} else {
			++$main::sent_message;
			$host->SendMsg(
				Message->new($host->{address}, 'Linux-x86', 'Clodhopper', '')
			) if $host->TimeStep == 1;
		}
	}
	if ($code == $Host::Recv) {
		++$main::received_message;
	}
};

$pinghost->AddSoftware($software);
$internet->AddHost($pinghost);

my $crsw = new Software 'Clodhopper',
q{
	my ($host, $software, $code, $msg) = @_;
    if ($code == $Host::Recv) {
		++$main::software_existed;
        $host->SendMsg(
            new Message
                $msg->{source},
                'Linux-x86',
                'Ping',
                ''
        );
	}
};

$pinghost->AddSoftware($crsw);

my $steps = 10;
$internet->Run(0, $steps);

my $errcnt = 0;

if ($main::software_existed == 0) {
	print STDERR "Software-to-remove never existed\n";
	++$errcnt;
}
if ($main::sent_message == 0) {
	print STDERR "Did not send message to software-to-remove\n";
	++$errcnt;
}
if ($main::received_message == 0) {
	print STDERR "Removing software never got message back\n";
	++$errcnt;
}
if ($main::tried_removal == 0) {
	print STDERR "Removing software never tried removal\n";
	++$errcnt;
}

# Check for current existance of "Clodhopper" Software...
foreach my $name (keys %{$internet->{software_count}}) {
	if ($name eq 'Clodhopper') {
		print STDERR "Found Clodhopper software in Network, despite removal\n";
		++$errcnt;
	}
}
print STDERR "Seed: ", $internet->GetSeed, "\n" if $errcnt;
exit $errcnt;
