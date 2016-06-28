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
my ($S, $I, $R, $N)
	= (9986, 7, 7, 10000);

# Probability of picking a host out of the network's address space
my $P = $N/65535.;

# length of timestep
my $delta_t = 1.0;

for (my $t = 0; $t < 150; $t += $delta_t) {

	printf "$t\t%.04f\t%.04f\t%.04f\n", $S, $I, $R;

	my $dR = $P * $I * $R / $N * $delta_t;
	my $dI = ($P * $I * $S / $N - $P * $I * $R / $N) * $delta_t;

	$I += $dI;
	$R += $dR;
	$S = $N - $I - $R;
}
