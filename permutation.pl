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
# $Id: permutation.pl,v 1.5 2003/08/29 04:03:09 bediger Exp $
use strict;
use diagnostics;

use vars qw{$opt_S $opt_A $opt_V $opt_w $opt_s $opt_x $opt_X $opt_h};
use Getopt::Std;
use NWS::Network;
use NWS::Message;
use NWS::Host;
use NWS::Software;

# Extend NWS::Host to do permutation scanning
use Permutation;

package Network;
sub PrintCountsX
{
	my $self = shift;

	my $header = '#step, msg count';
	my $msg_cnt = $self->{total_msg_count} - $self->{last_msg_count};
	my $data = "$self->{timestep}\t$msg_cnt";
    map { $header .= ",\t" . $_;
        $data   .= "\t" . $self->{software_count}->{$_}
    } sort keys %{$self->{software_count}};
	$header .= "\t" . 'total worms';
	$data .= "\t" .
		(($self->{software_count}->{'Pworm - Active'}?$self->{software_count}->{'Pworm - Active'}:0) + 
		($self->{software_count}->{'Pworm - Inactive'}?$self->{software_count}->{'Pworm - Inactive'}:0));
    print $header, "\n";
    print $data, "\n";
    $self->{last_msg_count} = $self->{total_msg_count};
	return $self;
}
1;
package main;

my ($seed, $address_space, $victim_cnt, $worm_cnt, $stop_proportion)
	= (0, 65535, 10000, 7, 0.01);

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

# NWS::Host instance that has non-exploitable Software
# instances to hold place in output.
my $placeholder = new Host 'OS-CPU', 0;
$placeholder->AddSoftware(new Software 'Pworm - Active', '', 0);
$placeholder->AddSoftware(new Software 'Pworm - Inactive', '', 0);
$placeholder->AddSoftware(new Software 'Bvictim', '', 0);
$network->AddHost($placeholder);

# Permutation scanning worm.
# Each worm counts the number of "overlaps", the number of times it probes
# an already infected host.  A real worm might want to do 3 or 4, just to
# avoid going inactive if it hits a host set up to spoof the worm.
my $Pworm_code = q{ my ($host, $software, $phase, $msg) = @_;
	if ($phase == $Host::Run) {
		if ($software->{overlaps} < 1) {
			# Use the same key all the time - all instances of Pworm on
			# the same permutation.
			my $addr;
			do {
				$addr = $host->encode($software->{sequence}++, 0x1a7bf329);
			} while ($addr == $host->{address});
			$software->{sequence} %= 65535;
			$host->SendMsg(
				new Message
					$addr,
					"OS-CPU",
					"Bvictim",
					$software->{function}
			);
		}
	} elsif ($phase == $Host::Init) {
		$software->{sequence} = int rand 65535;
		$software->{overlaps} = 0;
	} elsif ($phase == $Host::Init2) {
		$software->{true_name} = 'Pworm - Active';
		$software->{exploitable} = 0; # Pworm can't re-exploit this machine
		$software->{sequence} = int rand 65535;
		$software->{overlaps} = 0;
	} elsif ($phase == $Host::Recv) {
		# Have to distinguish between another Pworm trying to re-infect this Host,
		# and an already infected Host answering a probe from this Host.
		if (!$msg->{reinfection}) {
			# A previously infected Host just probed this Host.
			# Send a Message back to indicate infection.
			my $reply = new Message
					$msg->{source},
					"OS-CPU",
					"Bvictim",
					'';
			$reply->{reinfection} = 99;
			$host->SendMsg($reply);
		} elsif ($msg->{reinfection}) {
			# Just probed a previously infected Host. Reset
			# sequence number, and go inactive if this is the
			# Nth reply received.
			$software->{sequence} = int rand 65535;
			# You only need to count replies from previously infected
			# Hosts if you want to keep probing after getting a reply.
			# And you might in the Real World - someone may spoof a reply
			# from a non-infected host to get worms to turn themselves off.
			++$software->{overlaps};
			$software->{true_name} = 'Pworm - Inactive' unless $software->{overlaps} < 1;
		}
	}
};

for (my $i = 0; $i < $worm_cnt; ++$i) {
	my $host = new Host 'OS-CPU', 0;
	my $software = new Software 'Pworm - Active', $Pworm_code, 0;
	$host->AddSoftware($software);
	my $addr = $network->AddHost($host);
}

for (my $i = 1; $i < $victim_cnt; ++$i) {
	my $host2 = new Host 'OS-CPU', 0;
	my $sw3 = new Software 'Bvictim', '', 1; # no code, exploitable
	$host2->AddSoftware($sw3);
	my $addr = $network->AddHost($host2);
}

my $steps = 250;
my $delta = 5;
print STDERR "Running a Network through $steps time steps\n";

print "# Permutation scanning worm.\n";
print "# Address space size:    $address_space\n";
print "# Starting victim count: $victim_cnt\n";
print "# Starting worm count:   $worm_cnt\n";
print "# $steps total, print count every $delta steps\n";
print "# Random address seed:  " . $network->GetSeed . "\n";

my $start_timestamp = time;
#$network->PrintCountsX;
for (my $i = 1; $i < $steps; $i += $delta ) {
	$network->Run($i, $delta);
	$network->PrintCountsX;
	last if $network->{software_count}->{Bvictim}/$victim_cnt < $stop_proportion;
}
my $stop_timestamp = time;

my $elapsed_time = $stop_timestamp - $start_timestamp;
print "# Elapsed time:          $elapsed_time seconds\n";

# Proportion of Messages that actually hit a Host
my $hitness = $network->{total_hit_count}/$network->{total_msg_count};

my ($total_rcvd, $total_matched, $total_accepted, $total_exploited)
	= (0, 0, 0, 0);
foreach my $h (values %{$network->{hosts}}) {
	# need to tally up received, matched, accepted, exploited messages
	$total_rcvd += $h->{msg_cnt}->{rcvd};
	$total_matched += $h->{msg_cnt}->{matched};
	$total_accepted += $h->{msg_cnt}->{accepted};
	$total_exploited += $h->{msg_cnt}->{exploited};
}

print "# Total count of messages: $network->{total_msg_count}\n";
print "# Total of messages that hit a Host: $network->{total_hit_count}\n";
print "# Proportion of address space filled: $fullness\n";
print "# Proportion of messages that hit a Host:    $hitness\n";
print "# Total Host hits: ", $total_rcvd, "\n";
print "# Host hits matched: ", $total_matched, "\n";
print "# Host hits accepted: ", $total_accepted, "\n";
print "# Hosts exploited : ", $total_exploited, "\n";

sub numerically {$a<=>$b};

foreach my $address (sort numerically keys %{$network->{hosts}}) {
	my $host = $network->{hosts}->{$address};
	print "#hits\t", $address, "\t", $host->{msg_cnt}->{rcvd}, "\n";
}


exit 0;

sub usage
{
	print "$0: Permutation scanning network worm model\n";
	print "Options:   -S seed    set PRNG seed (default set randomly)\n";
	print "           -A size    set address space size (default 65535)\n";
	print "           -V number  set number of victim hosts (default 9999)\n";
	print "           -w number  set initial number of worm hosts (default 1)\n";
	print "           -s number  set proportion of remaining victim hosts to stop at (default 0.01)\n";
	exit 0;
}
