# Discrete time step simulation of network worms and fully-connected networks.

From September, 2003

The idea was to create an easy-to-use way to check all the assertions
the experts made about worms. If you'll recall, 2003 was about the peak
worm year, with "Slammer" in January, XXX, YYY and ZZZ throughout the
year.

Experts crawled out of the woodwork to explain 

## Installation

INSTALLATION OF NWS

NWS does not install the traditional Perl way
(perl Makefile.PL; make; make test; make install).  NWS doesn't constitute
a large amount of code, and I fully expect that users will make copies
of the library modules and modify them for the purposes of specific
simulations.

I expect that the easiest and best way to "install" is to have a per-project
copy of the NWS directory and its contents.  Create it something like this,
assuming that the NWS distribution file (nws.tar.gz) resides in /tmp:

    $ mkdir ~/mynws
    $ cd ~/mynws
    $ gunzip -c /tmp/nws.tar.gz | tar xf -
    $ mkdir ~/newsimulation
    $ cd ~/newsimulation
    $ cp -r ~/mynws/NWS .
    $ cp ~/mynws/generic.pl .
    $ ./generic.pl 
    
    Running a Network through 135 time steps
    # Generic SIS model with no disinfection.
    # Address space size:    65536
    # Random address allocation to hosts
    # Starting victim count: 10000
    # Starting worm count:   1
    # Total entities in population: 10001
    # 135 max, print count every 5 steps
    # Stop at 1% victims left uninfected
    # Random address seed:  478952942
    #step, msg count
    0       0
    #step, msg count,       Aworm,  Bvictim
    5       5       1       10000
    #step, msg count,       Aworm,  Bvictim
    10      5       1       10000
    ^C
    $ cp generic.pl slapper.pl
    $ vi slapper.pl
    	...

Hopefully, you get the picture.

### TROUBLESHOOTING

I did development of NWS on a SuSE 7.3 Linux machine, so the "#!"
line of generic.pl (or any simulation you write) may have to change.
If generic.pl fails with a message like:

    bash: ./generic.pl: bad interpreter: No such file or directory
or
    zsh: no such file or directory: ./generic.pl

Try doing `which perl` to see the fully-qualified path to the perl
interpreter.  Change the "#!" line as appropriate.

I don't think that the NWS code does anything too exotic: any Perl 5.x
interpreter should work.  I also don't think that NWS does anything
operating-system-dependent.  But anything's possible.
