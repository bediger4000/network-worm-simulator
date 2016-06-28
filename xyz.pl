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
# $Id: sir.pl,v 1.9 2003/09/20 05:01:28 bediger Exp $
use strict;
use diagnostics;

print "# Euler's method numerical simulation of SIR epidemic\n";
print "# See also: http://www.math.duke.edu/education/ccp/materials/postcalc/sir/contents.html\n";

# Initial values of counts of susceptible, infectious, recovered entities,
# and the population size.
my ($S, $A, $I, $N)
	= (9993, 7, 0, 10000);

my $P = $N/65535.;

# length of timestep
my $delta_t = 1.0;

for (my $t = 0; $t < 150; $t += $delta_t) {

	printf "$t\t%.04f\t%.04f\t%.04f\n", $S, $A, $I;

	my $dI = $P * $A * ($A + $I) / $N * $delta_t;
	my $dA = $P * $A * $S / $N * $delta_t - $dI;

	$A += $dA;
	$I += $dI;
	$S = $N - $I - $A;
}
