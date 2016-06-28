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
# $Id: Software.pm,v 1.3 2003/08/29 03:33:35 bediger Exp $
use strict; use diagnostics;
package Software;

# my $code_red_code = q/ ... /;
# Usage: my $software = new Software 'Code Red', $code_red_code, 1;
sub new {
	my ($type, $identifier, $code, $exploitable) = @_;
	my $ref = {
		identifier  => $identifier,
		function    => '',
		exploitable => $exploitable,
		true_name   => '',
	};
	# Start with True Name same as public identifier
	$ref->{true_name} = $ref->{identifier};

	# Compile the code.
	if ($code) {
		eval "\$ref->{function} = sub { $code };";
		print STDERR "Problem evaling code in new Software: $@\n" if $@;
	}

	bless $ref;
	return $ref;
}

1;
