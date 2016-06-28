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
# $Id: cheese.pl,v 1.6 2003/09/20 05:01:28 bediger Exp $
use strict;
use diagnostics;

use vars qw{$opt_S $opt_A $opt_V $opt_w $opt_c $opt_i $opt_x $opt_X $opt_h};
use Getopt::Std;
use NWS::Network;
use NWS::Host;
use NWS::Message;
use NWS::Software;

# Cheese worm code
my $cheese_code = q{
	my ($host, $software, $code, $msg) = @_;
	if ($code == $Host::Run) {
		$host->SendMsg(
			new Message
				$host->RandAddress,
				'Linux-x86',
				'1i0n backdoor',  # Cheese comes in via back door
				$software->{function}
		);
	} elsif ($code == $Host::Init2) {
		$software->{exploitable} = 0; # no longer exploitable
		$software->{true_name} = 'Cheese';
		# Remove the offending exploited software
		$host->RemoveSoftware('bind');
	} elsif ($code == $Host::Init) {
		$software->{true_name} = 'Cheese';
	}
};

# Lion worm code
my $lion_code = q{
	my ($host, $software, $code, $msg) = @_;
	if ($code == $Host::Run) {
        $host->SendMsg(
            new Message
                $host->RandAddress,
                "Linux-x86",
                "bind",
                $software->{function}
        );
    } elsif ($code == $Host::Init2) {
        $software->{true_name} = '1i0n';
		$software->{exploitable} = 0; # no longer exploitable
		# install back door
		$host->AddSoftware(Software->new('1i0n backdoor', '', 1));
    } elsif ($code == $Host::Init) {
        $software->{true_name} = '1i0n';
    }
};

# Can't really set a 'stop proportion' on instances of "bind" or
# anything - "bind" might disappear before "cheese" gets any
# traction.
my ($seed, $address_space, $victim_cnt, $lion_cnt, $cheese_cnt, $freesteps)
    = (0, 65535, 10000, 7, 7, 0);

getopt('S:A:V:w:c:i:');
    
$seed = $opt_S if $opt_S;
$address_space = $opt_A if $opt_A;
$victim_cnt = $opt_V if $opt_V;
$lion_cnt = $opt_w if $opt_w;
$cheese_cnt = $opt_c if $opt_c;
$freesteps = $opt_i if $opt_i; 

my $network = new Network $address_space, $seed;

# Add Lion host(s)
for (my $i = 0; $i < $lion_cnt; ++$i) {
	my $l1on_host = new Host 'Linux-x86', 0, Software->new('1i0n', $lion_code, 0);
	$network->AddHost($l1on_host);
}

# Add one placeholder host with "Cheese" and "1i0n backdoor" NWS::Software
my $fake_host = new Host 'Linux-x86', 0, Software->new('Cheese', '', 0);
# This "1i0n backdoor" not exploitable - I want it to stay in place
$fake_host->AddSoftware(Software->new('1i0n backdoor', '', 0));
$network->AddHost($fake_host);

# Put in BIND hosts
for (my $i = 0; $i < $victim_cnt; ++$i) {
	my $bindhost = new Host 'Linux-x86', 0;
	my $bind = new Software 'bind', '', 1; # exploitable
	$bindhost->AddSoftware($bind);
	$network->AddHost($bindhost);
}

my $steps = 150;
my $delta = 5;

print STDERR "Running a Network through $steps time steps\n";
print "# Random address seed: " . $network->GetSeed . "\n";
print "# Address space size:    $address_space\n";
print "# Starting victim count: $victim_cnt\n";
print "# Starting worm count:   $lion_cnt\n";
print "# $steps total timesteps, print count every $delta steps\n";
print "# Random address seed:  " . $network->GetSeed . "\n";

my $start_timestamp = time;
$network->PrintCounts;

# Run for for a few steps to let Code Red get a good hold on the network
for (my $i = 1; $i < $freesteps; $i += $delta ) {
	$network->Run($i, $delta);
	$network->PrintCounts;
}

print "# Putting in $cheese_cnt Cheese hosts - note that the count of\n";
print "# Cheese and '1ion backdoor' Software will be off-by-one, due to\n";
print "# the placeholder host.\n";
for (my $i = 0; $i < $cheese_cnt; ++$i) {
	my $crchost = new Host 'Linux-x86', 0, Software->new('Cheese', $cheese_code, 0);
	$network->AddHost($crchost);
}

# Run out the rest of the time steps
for (my $i = $freesteps + 1; $i < $steps; $i += $delta ) {
	$network->Run($i, $delta)->PrintCounts;
}

my $stop_timestamp = time;

my $elapsed_time = $stop_timestamp - $start_timestamp;

print "# Elapsed time:          $elapsed_time seconds\n";
print "# Total count of messages: $network->{total_msg_count}\n";
print "# Total of messages that hit a Host: $network->{total_hit_count}\n";

exit 0;
