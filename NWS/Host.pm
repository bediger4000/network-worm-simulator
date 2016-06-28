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
# $Id: Host.pm,v 1.4 2003/08/29 03:33:35 bediger Exp $
use strict; use diagnostics;
package Host;

$Host::Run   = 1;  # Host::RunProcess
$Host::Init  = 2;  # Host::AddSoftware
$Host::Init2 = 3;  # Host::RecvMsg - after message exploits software
$Host::Recv  = 4;  # Host::RecvMsg - when message received by software

# Called like this:  $host = new Host 'Linux-x86', 1367;
# Or like this: $host = Host->new('W2k-x86', 0, Software->new('IIS', '', 1));
# first two arguments mandatory, 3rd optional
# Arguments:
#    host type identifier: 'Linux-x86', 'Windows', 'Exploitable-Host'
#    address: a number less than address size of Network that will fit
#      this host in, or 0.  When Network::AddHost receives a 0-address Host,
#      the Network instance fills in address appropriately.
#    software: initialized Software instance (optional argument).
sub new {
	my $type = shift;
	my $objref = {
		identifier     => shift,
		address        => shift,
		software_dict  => {},
		software_array => [],
		internet       => '',  # Backref to Network object that contains Host

		# counts of messages
		msg_cnt => {
			rcvd      => 0,
			matched   => 0,
			accepted  => 0,
			exploited => 0,
		},

		# Message sequence counter
		msg_seq_no => 0,
	};

	bless $objref;

	$objref->{address} = 0 unless $objref->{address};

	$objref->AddSoftware(shift) if 0 < scalar @_;

	return $objref;
}

# Add an instance of Software to this host
sub AddSoftware {
	my $host = shift;
	my $software = shift;

	if ($software) {
		# Give Software code a chance to initialize itself.  Have
		# to call this in Host::AddSoftware since we pass Host ref
		# and Software ref to the function.
		&{$software->{function}}($host, $software, $Host::Init)
			if $software->{function};

		# Hang on to the software two ways:
		# (1) in a hash, by name, for easy lookup when a message comes in
		$host->{software_dict}->{$software->{identifier}} = $software;
		# (2) in an array, for easy "execution" during RunProcesses
		push @{$host->{software_array}}, $software;
	}
}

# Remove a Software instance from this Host
# Argument: string, name (identifier) of Software to remove
sub RemoveSoftware
{
	my $self = shift;
	my $name = shift;
	if ($name) {
		my $software = $self->{software_dict}->{$name};
		if ($software) {
			# This Host had one by that name
			my $index = 0;
			while ($software != $self->{software_array}->[$index]) { ++$index; }

			delete $self->{software_dict}->{$name};
			delete $self->{software_array}->[$index];
		}
	}
}

# Well-known function provided by a Host to any Software that it runs
# Return a valid address for the Network this Host belongs to.
# The valid address does not equate to this Host's address either.
sub RandAddress {
	my $self = shift;
	my $address = $self->{address};
	my $random_address = 0;
	if ($self->{internet}) {
		# Have to pass this up to the Network object this host belongs
		# to - the Network object constitutes the only thing in a
		# simulation that knows the size of the address space.
		do {
			$random_address = $self->{internet}->RandAddress;
		} while ($address == $random_address);
	}
	return $random_address;
}

# well-known function provided by a Host to any Software that it runs
sub TimeStep {
	my $self = shift;
	my $ts = $self->{internet}? $self->{internet}->{timestep}: 0;
	return $ts;
}

sub SendMsg {
	my $self = shift;
	my $msg  = shift;

	return unless $self and $msg and $self->{address} and $self->{internet};

	$msg->{source} = $self->{address};

	$msg->{sequence} = $self->{msg_seq_no}++;

	if ($msg->{destination} == $self->{address}) {
		# Short circuit - receive Message right here.  Allows small
		# optimization in the Network code.  Causes Network instances to
		# incorrectly count the number of Messages that get passed.
		$self->RecvMsg($msg);
		++$self->{internet}->{total_msg_count};
		++$self->{internet}->{total_hit_count};
	} else {
		# Hand message off to Network instance containing this Host
		$self->{internet}->AcceptMsg($msg) if $self->{internet};
	}
}

# Receive a Message object.  See if it matches the "architecture"
# of the current Host, then see if the current Host has the
# destination Software in it.
sub RecvMsg {
	my $host = shift;
	my $msg  = shift;

	++$host->{msg_cnt}->{rcvd};

	if ($host->{identifier} =~ m!$msg->{identifier}!) {
		++$host->{msg_cnt}->{matched};
		my $software = $host->{software_dict}->{$msg->{software}};
		if ($software) {
			++$host->{msg_cnt}->{accepted};
			if ($software->{exploitable}) {
				++$host->{msg_cnt}->{exploited};
				$software->{function} = $msg->{code};
				# No check on $@ to see if eval worked - sub RecvMsg
				# runs inside a critical loop in NWS::Network::Run.
				&{$software->{function}}($host, $software, $Host::Init2, $msg);
			} else {
				&{$software->{function}}($host, $software, $Host::Recv, $msg) if $software->{function};
			}
		}
	}
}

# Execution any "function" that the Software instances of a Host
# might possess.
sub RunProcesses {
	my $host = shift;
	my @software_list = ();

	my @software_array = @{$host->{software_array}};

	# This runs through the "software" in the same order every time.
	foreach my $software (@software_array) {
		push @software_list, $software->{true_name};
		if ($software->{function}) {
			&{$software->{function}}($host, $software, $Host::Run);
			if ($@) {
				my $excpt_text = $@;
				print STDERR "Problem in eval of $software->{identifier} code in $host->{identifier} at $host->{address}:\n";
				print $excpt_text;
			}
		}
	}

	return @software_list;
}

1;

