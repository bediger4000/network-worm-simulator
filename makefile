# $Id: makefile,v 1.23 2003/09/20 05:03:42 bediger Exp $
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

# target 'all' doesn't depend on WORMFIGHT - that target
# takes a lot of time to run, and the paper doesn't depend
# on it directly.
all: simple.out graphs zip web

# Have to run this - it constitutes the "simple example" in the paper
simple.out: simple.pl
	./simple.pl > simple.out
sir.out: sir.pl
	./sir.pl > sir.out

zip:
	tar czf nws.tar.gz makefile NWS *.pl *.plots index.html Permutation.pm runwf wf1.reduce mkhist COPYING INSTALL

web:
	rm -rf nws_web
	mkdir nws_web
	cp nws.tar.gz *.png index.html *.pl Permutation.pm index.html nws_web

WORMFIGHT: WORMFIGHT2 WORMFIGHT3

WORMFIGHT2: wf20.dat wf21.dat wf25.dat wf210.dat

wormfight2_0: wormfight2.pl runwf
	./runwf -z '-v 0' -d wormfight2_0 -p wormfight2.pl -m 20
wormfight2_1: wormfight2.pl runwf
	./runwf -z '-v 1' -d wormfight2_1 -p wormfight2.pl -m 20
wormfight2_5: wormfight2.pl runwf
	./runwf -z '-v 5' -d wormfight2_5 -p wormfight2.pl -m 20
wormfight2_10: wormfight2.pl runwf
	./runwf -z '-v 10' -d wormfight2_10 -p wormfight2.pl -m 20

wf2_0.raw wf20.dat: wf1.reduce wormfight2_0
	wf1.reduce wormfight2_0 > wf20.dat
wf2_1.raw wf21.dat: wf1.reduce wormfight2_1
	wf1.reduce wormfight2_1 > wf21.dat
wf2_5.raw wf25.dat: wf1.reduce wormfight2_5
	wf1.reduce wormfight2_5 > wf25.dat
wf2_10.raw wf210.dat: wf1.reduce wormfight2_10
	wf1.reduce wormfight2_10 > wf210.dat

WORMFIGHT3: wormfight3.pl runwf wf1.reduce
	./runwf -d wormfight3 -p wormfight3.pl -m 20
	wf1.reduce wormfight3 > wf3.dat

# Run SIS simulation 20 times, calculating mean values of
# number of infected hosts at each timestep.
SISMEAN: generic.pl runwf sir_mean.pl sis.pl discrete_sis.pl
	./runwf -d gentest -p generic.pl -z '-w 7 -V 9993' -m 20
	./sir_mean.pl gentest/*.out > mean.dat
	./sis.pl > sis.out
	./discrete_sis.pl > discrete_sis.out

# Run SIR (CRclean) simulation 20 times, calculating
# mean values of susceptible (IIS), infected (Code Red),
# resistant (CRclean) at each timestep
SIRMEAN: crclean.pl runwf sir_mean.pl 
	./runwf -d crcleantest -p crclean.pl -z '-w 7 -c 7 -V 9986' -m 20
	./sir_mean.pl crcleantest/*.out > crclean.dat

# Run 1i0n/Cheese simulation 20 times
CHEESEMEAN: cheese.pl runwf sir_mean.pl sir.out
	./runwf -z '-w 7 -c 7 -V 9986' -d cheese_mean -p cheese.pl -m 20
	./sir_mean.pl cheese_mean/*.out > cheese_mean.dat

PERMUTATION: runwf permutation.pl Permutation.pm sir_mean.pl mkhist random.hist
	./runwf -p permutation.pl -d permutation -m 20 -z '-w 7 -V 9993'
	./sir_mean.pl permutation/wf*.out > permutation.dat
	./mkhist permutation/*.out  > permutation.hist

random.hist:
	./mkhist gentest/*.out      > random.hist

MSBLAST: msblast.pl runwf sir_mean.pl mkhist random.hist
	./runwf -d msblast.random -p msblast.pl -z '-w 7 -V 9993' -m 20
	./sir_mean.pl msblast.random/*.out > msblast_random_mean.dat
	./mkhist msblast.random/*.out > msblast.random.hist
	./runwf -d msblast.banded -p msblast.pl -z '-w 7 -V 9993 -B 9' -m 20
	./sir_mean.pl msblast.banded/*.out > msblast_banded_mean.dat
	./mkhist msblast.banded/*.out > msblast.banded.hist
	./runwf -d random.banded -p generic.pl -z '-w 7 -V 9993 -B 9' -m 20
	./sir_mean.pl random.banded/*.out > random.banded.dat
	./mkhist random.banded/*.out > random.banded.hist


graphs: SISMEAN SIRMEAN CHEESEMEAN PERMUTATION MSBLAST sir.out
	gnuplot permutation.plots
	gnuplot sir.plots
	gnuplot cheese.plots
	gnuplot mean.plots
	gnuplot msblast.plots

lint:
	xmllint -noout -valid index.html

tests: test
test:
	./test_host.pl
	./test_network.pl
	./removetest.pl
	./selfmsg.pl
	./worm_execution.pl
	./worm_exploit.pl
	./message_delivery.pl
	./addr_space_end.pl
	./all_messages.pl > /dev/null

cleangraphs:
	-rm -rf *.png

clean:
	-rm -f *.out
	-rm -f *.png
	-rm -f *.hist
	-rm -rf nws_web nws.tar.gz
	-rm -rf gentest address_space_ends wormfight2_* wormfight3 crcleantest cheese_mean permutation msblast
	-rm -rf mean.dat wf*.raw wf*.dat crclean.dat cheese_mean.dat permutation.dat
	-rm -rf msblast_banded_mean.dat msblast_random_mean.dat random.banded.dat
	-rm -rf msblast.banded msblast.random random.banded
