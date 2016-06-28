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
# $Id: sis.pl,v 1.6 2003/08/29 04:03:09 bediger Exp $
use strict;
use diagnostics;

# This simulation seems to approach the exact solution from
# "beneath" - the larger the timestep, the less agressive
# the infection.
# Exact solution:
# v = N * v_zero /(v_zero + (1 - v_zero)*exp(-beta * t))
# N = 10000, the number of infectible entities, or size of population
# v_zero = 1./10000., the initial proportion of infected entities
# beta = 10000/65535, probability of picking a host out of the address space

my $N = 10000.;

my $beta = $N/65535.;

# Use a timestep length of 1.0 to more closely match the NWS simulation.
my $delta_t = 1.0;

# v set to v_zero, initial proportion of infected entities
my $v = 7./$N;

print "# SIS numerical simulation\n";
print "# Initial proportion of entities infected: ", $v, "\n";
print "# Probability of infection: ", $beta, "\n";

print "# timestep, susceptible, infected\n";

for (my $i = 0; (1. - $v) > 0.01; $i += $delta_t) {
	my $U = $N * (1. - $v);
	my $I = $N * $v;
	print "$i\t$U\t$I\n";
	$v += $beta * $v * (1. - $v) * $delta_t;
}
