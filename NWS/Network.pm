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
# $Id: Network.pm,v 1.7 2003/08/29 03:33:35 bediger Exp $
use strict; use diagnostics;

# If a Network object had an address (or range of addresses) in another
# Network object, you could simulate the effects of firewalls, or
# intranets behind routers doing NAT.  Instances of Network would have
# to have somewhat more code in that case.
# If a Network object had some kind of rate limitation, it could
# simulate a network that can get overloaded by worm traffic.

package Network;

# Usage: my $network = new Network $max_address, $seed;
# $max_address evaluates to the maximum address used by Network
# instance.  $seed value used to seed random number generator.
# $max_address mandatory, it calculates a seed if $seed
# is undefined or false.
sub new {
	my $type = shift;

	my $objref = {
		hosts          => {},
		max_address    => shift,
		seed           => shift,
		software_count => {},
		timestep       => 0,
		total_msg_count=> 0,
		last_msg_count => 0,
		total_hit_count=> 0,
		msg_queue      => [],
	};

	# Fill it in with what value?
	die "Don't know how big to make the address space.\n" if !$objref->{max_address};

	$objref->{seed} = time() ^ ($$ + ($$ << 15)) if !$objref->{seed};

	srand($objref->{seed});

	bless $objref;
	return $objref;
}

# Return a random address in the Network's address space.
# Perl "rand EXPR" builtin returns a number great than
# or equal to zero, and less than the value of EXPR.
# Address zero doesn't get used - see sub AddHost. And
# the max address won't ever get returned unless EXPR
# ends up as 1 more than the max address.
sub RandAddress {
	my $self = shift;
	my $addr = 0;
	$addr = int rand ($self->{max_address} + 1) while $addr == 0;
	return $addr;
}

# Used externally as (ugh!) accessor method.
# If you want to repeat a run exactly, you need to know what
# number with which to seed the random number generator.
sub GetSeed {
	my $self = shift;
	return $self->{seed};
}

# Add a Host instance to a Network instance.
# Usage: my $addr = $network->AddHost($host);
# If you haven't set address of $host, Network
# instance will give $host a random address.
# Returns the address of the Host just added.
sub AddHost {
	my $self = shift;
	my $host = shift;

	$host->{internet} = $self;

	# If host doesn't have an address, set one.
	# This doesn't put a Host instance at address zero.
	if (!$host->{address}) {
		do {
			$host->{address} = $self->RandAddress;
		} while (!$host->{address} || $self->{hosts}->{$host->{address}});
	}

	# Hang on to the Host in a hash, keyed by address, for easy lookup
	# when delivering messages.  This code does not insert a Host
	# instance that has an address outside the Network's address space.
	unless ($host->{address} > 0 and $host->{address} > $self->{max_address}) {
		$self->{hosts}->{$host->{address}} = $host
	} else {
		# Mark this Host as having a bad address.  Also used as error return.
		$host->{address} = -1;
	}

	# The keyed-by-address hash really consitutes "The Network".

	return $host->{address};
}

# sub AcceptMsg conceals the exact implementation of how
# NWS::Network holds and sets up delivery of the NWS::Message objects.
# Can't just push the Messages onto a queue - since Network::Run
# just plows through the %Network::hosts thing in "values" order
# every time, a queue could give Hosts low in the array an advantage.
sub AcceptMsg
{
	my $self = shift;
	# Splice the argument into Network::msg_queue array ref.
	# Have to add 2 to the "last index" of the msg_queue array:
	# +1 to get size of array, +1 more to allow the splice to
	# put the new element at the end of the array.
	splice @{$self->{msg_queue}}, int rand ($#{$self->{msg_queue}} + 2), 0, shift;
}

# Run all the Network instance's Hosts through some time steps.
# Usage: $network->Run($start_step, $delta);
# Starting at a timestep equal to the value of $start_step, execute 
# $delta timesteps.
# This allows you to start at 0, and examine a Network object and the
# Network and the Host instances it contains at desired intervals.
sub Run {
	my $self = shift;
	my $start_step = shift;
	my $steps = shift;

	# Make a local variable holding hash of hosts to avoid all the notation
	# of dereferencing of $self.
	my %hosts = %{$self->{hosts}};
	my @host  = values %hosts;

	$steps += $start_step; # since the $steps argument is a delta

	for(my $x = $start_step; $x < $steps; ++$x) {

		$self->{timestep} = $x;

		$self->{software_count} = {};

		# Call Host::RunProcesses on each Host instance, use array of Hosts
		# for speed and convenience.
		foreach my $h (@host) {
			map { ++$self->{software_count}->{$_} if $_ } $h->RunProcesses;
		}

		# Deliver all the Messages sent out during Host::RunProcesses execution
		# This loop and the subs it calls constitutes the main consumption
		# of execution time.  Don't add to it unnecessarily.
		# Unfortunately, to even come close to counting all Messages sent,
		# you have to increment a counter inside the loop: reception of a
		# a Message can trigger a Host to send another Message.
		while (my $msg = shift @{$self->{msg_queue}}) {
			my $dest_host;
			++$self->{total_msg_count};
			next unless ($dest_host = $hosts{$msg->{destination}});
			$dest_host->RecvMsg($msg);
			++$self->{total_hit_count};
		} 
	}
	return $self;
}

sub PrintCounts
{
	my $self = shift;

	my $header = '#step, msg count';
	my $msg_cnt = $self->{total_msg_count} - $self->{last_msg_count};
	my $data = "$self->{timestep}\t$msg_cnt";
    map { $header .= ",\t" . $_;
        $data   .= "\t" . $self->{software_count}->{$_}
    } sort keys %{$self->{software_count}};
    print $header, "\n";
    print $data, "\n";
    $self->{last_msg_count} = $self->{total_msg_count};
	return $self;
}

1;
