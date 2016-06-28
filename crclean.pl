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
# $Id: crclean.pl,v 1.8 2003/09/20 05:01:28 bediger Exp $
use strict;
use diagnostics;

use vars qw{$opt_S $opt_A $opt_V $opt_w $opt_c $opt_i $opt_x $opt_X $opt_h};
use Getopt::Std;
use NWS::Network;
use NWS::Host;
use NWS::Message;
use NWS::Software;

my $crclean_code = q{
	# CRClean code
	my ($host, $software, $code, $msg) = @_;
	if ($code == $Host::Recv) {
		$host->SendMsg(
			new Message
				$msg->{source},
				'Windows-x86',
				'IIS',
				$software->{function}
		);
	} elsif ($code == $Host::Init2) {
		$software->{exploitable} = 0; # no longer exploitable
		$software->{identifier} = 'IIS';
		$software->{true_name} = 'CRClean';
	} elsif ($code == $Host::Init) {
		# set "true name" on installation
		$software->{true_name} = 'CRClean';
	}
};

my $cr_code = q{
	# Code Red "source code"
	my ($host, $software, $code, $msg) = @_;
	if ($code == $Host::Run) {
		# Host::RandAddress never returns the address of $host,
		# so this code cannot re-infect itself.
        $host->SendMsg(
            new Message
                $host->RandAddress,
                "Windows-x86",
                "IIS",
                $software->{function}
        );
    } elsif ($code == $Host::Init2 or $code == $Host::Init) {
        $software->{true_name} = 'Code Red';
    }
}, 1;

my ($seed, $address_space, $victim_cnt, $worm_cnt, $crclean_cnt, $freesteps)
    = (0, 65535, 10000, 1, 1, 0);

getopt('S:A:V:w:c:i:');

$seed = $opt_S if $opt_S;
$address_space = $opt_A if $opt_A;
$victim_cnt = $opt_V if $opt_V;
$worm_cnt = $opt_w if $opt_w;
$crclean_cnt = $opt_c if $opt_c;
$freesteps = $opt_i if $opt_i;
&usage if $opt_x or $opt_X or $opt_h;


my $network = new Network $address_space, $seed;

# Add Code Red host(s)
for (my $i = 0; $i < $worm_cnt; ++$i) {
	my $crhost = new Host 'Windows-x86', 0, Software->new('IIS', $cr_code, 1);
	$network->AddHost($crhost);
}

# Add one Host without code to hold place(s) in output
my $fake_host = new Host 'Windows-x86', 0, Software->new('CRClean', '', 0);
$fake_host->AddSoftware(Software->new('IIS', '', 0));
$fake_host->AddSoftware(Software->new('Code Red', '', 0));
$network->AddHost($fake_host);

# Put in IIS hosts
for (my $i = 0; $i < $victim_cnt; ++$i) {

	my $iishost = new Host 'Windows-x86', 0;
	my $sw3 = new Software 'IIS', '', 1; # exploitable
	$iishost->AddSoftware($sw3);
	$network->AddHost($iishost);
}

my $steps = 150;
my $delta = 5;

print STDERR "Running a Network through $steps time steps\n";
print "# Random address seed: " . $network->GetSeed . "\n";
print "# Address space size:    $address_space\n";
print "# Starting IIS host count: $victim_cnt\n";
print "# Starting Code Red host count:   $worm_cnt\n";
print "# Executing $steps total timesteps, print count every $delta steps\n";
print "# Random address seed:  " . $network->GetSeed . "\n";
print "# Executing $freesteps timesteps before introducing CRclean host\n";
print "# CRclean host count:   $crclean_cnt\n";
print "# Counts off by 1 for Code Red, IIS and CRclean Software due to placeholder\n";


my $start_timestamp = time;
$network->PrintCounts;

# Run for for a few steps to let Code Red get a good hold on the network
for (my $i = 1; $i < $freesteps; $i += $delta ) {
	$network->Run($i, $delta)->PrintCounts;
}

print "# Putting in $crclean_cnt CRClean hosts\n";
# Put some "CRClean" hosts in
for (my $i = 0; $i < $crclean_cnt; ++$i)
{
	my $crchost = new Host 'Windows-x86', 0, Software->new('IIS', $crclean_code, 0);
	$network->AddHost($crchost);
}

# Run out the rest of the time steps
for (my $i = $freesteps + 1; $i < $steps; $i += $delta ) {
	$network->Run($i, $delta)->PrintCounts;
}

my $stop_timestamp = time;

my $elapsed_time = $stop_timestamp - $start_timestamp;
print "# Elapsed time:          $elapsed_time seconds\n";

# Add 1 to theoretical count of hosts for the "placekeeper" host
my $theoretical_hosts = $victim_cnt + $worm_cnt + $crclean_cnt + 1;
my $real_hosts = scalar keys %{$network->{hosts}};

print "# Total count of messages: $network->{total_msg_count}\n";
print "# Total of messages that hit a Host: $network->{total_hit_count}\n";
print "# Found $real_hosts hosts, should have found $theoretical_hosts\n";

exit 0;

sub usage
{
	print "$0: Susceptible-Infected-Resistant network worm model\n";
	print "Options:   -S seed    set PRNG seed (default set randomly)\n";
	print "           -A size    set address space size (default 65535)\n";
	print "           -V number  set number of IIS hosts (default 10000)\n";
	print "           -w number  set initial number of Code Red hosts (default 1)\n";
	print "           -c number  set initial number of CRclean hosts (default 1)\n";
	print "           -i number  set elapsed timesteps to execute before CRclean host(s) introduced (default 0)\n";
	exit 0;
}
