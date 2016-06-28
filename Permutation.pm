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
use strict;
use diagnostics;
# $Id: Permutation.pm,v 1.3 2003/08/29 03:58:01 bediger Exp $

package Host;

# Add 2 methods to Host objects:
# encode() and decode().

# encode() constitutes a DES-inspired algorithmic permutation.
# Uses a 32-bit key, and only does 4 rounds of combining key
# with 16-bit block.
# Encodes a 16 bit block into another 16 bit block.

# Permutations chosen randomly.  Might not comprise the "best"
# permutations.  In this case "best" has something to do with
# how a given encoded value correlates to the original value.
my @permutation1 = (
244, 88, 233, 216, 53, 9, 58, 173, 146, 6, 127, 92, 198, 208, 156, 94, 
115, 14, 211, 171, 199, 132, 112, 193, 131, 118, 129, 62, 157, 16, 84, 245, 
48, 59, 122, 209, 177, 150, 154, 141, 71, 72, 57, 133, 202, 231, 237, 76, 
148, 47, 138, 25, 252, 195, 87, 74, 34, 81, 160, 159, 13, 188, 21, 158, 
139, 108, 104, 238, 170, 214, 18, 86, 29, 119, 205, 26, 30, 63, 12, 73, 
70, 100, 39, 43, 147, 126, 120, 247, 249, 17, 55, 111, 248, 101, 204, 255, 
38, 40, 2, 102, 180, 201, 149, 187, 99, 109, 164, 169, 194, 110, 153, 50, 
174, 98, 191, 243, 77, 178, 44, 5, 182, 172, 128, 165, 223, 167, 152, 65, 
185, 45, 242, 96, 228, 251, 253, 19, 56, 168, 197, 184, 175, 89, 10, 27, 
36, 79, 239, 97, 8, 54, 82, 162, 107, 222, 183, 33, 232, 224, 206, 226, 
91, 246, 32, 130, 124, 117, 68, 28, 116, 1, 93, 136, 11, 212, 210, 106, 
137, 236, 52, 220, 134, 64, 250, 114, 49, 35, 31, 186, 190, 218, 15, 80, 
85, 90, 155, 225, 24, 241, 3, 219, 51, 176, 46, 217, 67, 113, 234, 23, 
37, 196, 105, 66, 151, 4, 213, 230, 103, 227, 189, 75, 143, 69, 78, 142, 
42, 61, 161, 235, 135, 163, 125, 145, 7, 254, 240, 20, 181, 207, 200, 144, 
83, 229, 123, 41, 60, 179, 192, 221, 0, 203, 215, 166, 121, 95, 140, 22, 
);
my @permutation2 = (
138, 161, 193, 54, 186, 204, 129, 221, 171, 30, 245, 163, 41, 72, 224, 207, 
232, 216, 235, 166, 191, 172, 200, 75, 22, 174, 187, 122, 236, 46, 10, 239, 
52, 105, 134, 115, 155, 143, 132, 244, 33, 67, 44, 5, 55, 80, 21, 16, 
8, 142, 133, 69, 252, 6, 89, 23, 19, 78, 159, 141, 45, 24, 226, 99, 
1, 94, 58, 59, 205, 100, 151, 164, 95, 17, 223, 4, 84, 218, 202, 14, 
104, 11, 107, 18, 131, 106, 228, 199, 198, 82, 27, 40, 225, 66, 12, 208, 
112, 32, 158, 65, 195, 240, 136, 219, 242, 176, 234, 121, 127, 243, 210, 251, 
237, 137, 36, 81, 83, 68, 135, 38, 64, 160, 233, 140, 148, 96, 170, 25, 
247, 255, 60, 183, 26, 215, 147, 250, 102, 31, 203, 3, 152, 168, 113, 13, 
189, 173, 231, 29, 70, 213, 196, 154, 128, 246, 56, 117, 48, 92, 116, 98, 
123, 249, 212, 76, 53, 130, 229, 20, 124, 149, 179, 145, 63, 175, 103, 238, 
169, 35, 197, 146, 153, 90, 167, 144, 192, 125, 39, 37, 7, 79, 126, 51, 
156, 194, 217, 15, 182, 73, 157, 209, 139, 49, 253, 101, 93, 62, 220, 185, 
50, 165, 111, 181, 74, 86, 57, 110, 0, 180, 162, 177, 227, 77, 206, 2, 
211, 97, 214, 230, 85, 88, 114, 178, 248, 71, 43, 184, 47, 150, 61, 119, 
109, 108, 87, 9, 201, 28, 254, 241, 222, 42, 91, 118, 190, 188, 120, 34, 
);

# It differs from DES here too - it doesn't "widen" from 32 to 48 bits
# in the first permutation like DES' "expansion permutation" does,
# the 2nd permutation isn't of the same quality as the DES S-box
# thing, either.
sub f
{
	my ($key, $R) = @_;
	return $permutation2[$permutation1[$R] ^ $key];
}

sub encode
{
	use integer;
	my ($self, $val, $key) = @_;

	# The 4-byte key actually gets used as 4, single-byte
	# sub-keys.
	my @key = (
		$key & 0xff,
		($key >> 8) & 0xff,
		($key >> 16) & 0xff,
		($key >> 24) & 0xff,
	);

	# This part makes it explictly 16-bit, I suppose.
	my ($L, $R) = (($val >> 8) & 0xff, $val & 0xff);

	# 4 rounds of combining input bytes with key bytes.
	# This is very similar to DES - the difference coming from
	# what function f does to the key and the right-hand half
	# of the value.
	for (my $i = 0; $i < 4; ++$i) {
		my $Rprev = $R;
		$R = &f($key[$i], $R) ^ $L;
		$L = $Rprev;
	}

	return (($L << 8) | $R);
}

# work sub encode backwards.
sub decode
{
	use integer;
	my ($self, $val, $key) = @_;

	my @key = (
		($key >> 24) & 0xff,
		($key >> 16) & 0xff,
		($key >> 8) & 0xff,
		$key & 0xff,
	);

	my ($L, $R) = (($val >> 8) & 0xff, $val & 0xff);

	for (my $i = 0; $i < 4; ++$i) {
		my $Rprev = $L;
		$L = &f($key[$i], $Rprev) ^ $R;
		$R = $Rprev;
	}

	return (($L << 8) | $R);
}

1;
