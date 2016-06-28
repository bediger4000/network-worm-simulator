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
# $Id: discrete_sis.pl,v 1.2 2003/08/29 04:03:09 bediger Exp $
use strict;
use diagnostics;

# Exact solution:
# v = N * v_zero /(v_zero + (1 - v_zero)*exp(-beta * t))
# N = 10000, the number of infectible entities, or size of population
# v_zero = 1./10000., the initial proportion of infected entities
# beta = 10000/65535, probability of picking a host out of the address space

# This particular simulation approximates the "discrete" nature of NWS:
# you can't have 1.22 hosts infected, only 1 or 2, depending on probabilities.
# This simulation works in absolute numbers of infected and susceptible hosts,
# not in proportions.
# delta-I = floor(P * I * (1. - I/N) * delta-T)
# I - number of infected entities
# N - total size of population 
# P - probability of infecting an entity
# S = N - I
#
# I choose P = 10000/65535 = .1525 to match NWS simulation
# Initial I set to 7 so that delta-I comes out to 1, and the
# simulated epidemic can "take off".

my $N = 10000.;

my $beta = $N/65535.;

# Use a timestep length of 1.0 to more closely match the NWS simulation.
my $delta_t = 1.0;

# v set to v_zero, initial proportion of infected entities
my $V = 7;

print "# SIS numerical simulation\n";
print "# Initial number of entities infected: ", $V, "\n";
print "# Probability of infection: ", $beta, "\n";

print "# timestep, susceptible, infected\n";

for (my $i = 0; $i < 135; $i += $delta_t) {
	my $U = $N - $V;
	print "$i\t$U\t$V\n";
	$V += int($beta * $V * (1. - $V/$N) * $delta_t);
}
