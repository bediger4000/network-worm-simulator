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
# $Id: sir_mean.pl,v 1.2 2003/08/29 04:03:09 bediger Exp $
use strict;
use diagnostics;

my %by_timestep2 = ();
my %by_timestep3 = ();
my %by_timestep4 = ();
my %by_timestep5 = ();
my %by_timestep6 = ();
my %timestep_cnt = ();

while (<>) {
	next if /^#/;
	chop;
	my @a = split /\t/;
	#next if 5 > scalar @a;
	# Save 2nd, 3rd, 4th, 5th, 6th columns by timestep value
	$by_timestep2{$a[0]} += $a[1] if $a[1];
	$by_timestep3{$a[0]} += $a[2] if $a[2];
	$by_timestep4{$a[0]} += $a[3] if $a[3];
	$by_timestep5{$a[0]} += $a[4] if $a[4];
	$by_timestep6{$a[0]} += $a[5] if $a[5];
	# Count how many occurances of each timestep occur
	++$timestep_cnt{$a[0]};
}

sub numerically {$a<=>$b;}

foreach my $timestep (sort numerically keys %by_timestep3) {
	print $timestep, "\t",
		$by_timestep2{$timestep}?$by_timestep2{$timestep}/$timestep_cnt{$timestep}:0, "\t",
		$by_timestep3{$timestep}?$by_timestep3{$timestep}/$timestep_cnt{$timestep}:0, "\t",
		$by_timestep4{$timestep}?$by_timestep4{$timestep}/$timestep_cnt{$timestep}:0, "\t",
		$by_timestep5{$timestep}?$by_timestep5{$timestep}/$timestep_cnt{$timestep}:0, "\t",
		$by_timestep6{$timestep}?$by_timestep6{$timestep}/$timestep_cnt{$timestep}:0, "\t",
		"\n"
	;
}

exit 0;
