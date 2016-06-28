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
# $Id: Message.pm,v 1.2 2003/08/29 03:33:35 bediger Exp $
use strict; use diagnostics;
package Message;

# Usage: my $msg = new Message $dest_address, $dest_host_type,
#			$dest_software, $exploit_code;
sub new {
	my $type = shift;
	my $ref = {
		destination => shift,   # To Host address
		source      => '',      # From Host address
		identifier  => shift,   # identifier of "To Host"
		software    => shift,   # name of software on "To Host"
		code        => shift,   # source code of exploit/worm
		sequence    => 0,       # Message sequence no. (set by sending Host)
	};
	bless $ref;
	return $ref;
}

1;
