# Discrete time step simulation of network worms and fully-connected networks.

### From September, 2003

The project is supposed to constitute an easy-to-use way to check all the
assertions the experts made about worms. If you'll recall, 2003 was about the
peak worm year, with "Slammer" in January, Blaster, Welchia and Sobig in August,
and many minor worms throughout.

Experts crawled out of the woodwork to explain what was happening and why. I
felt like the experts were speaking through their hats, with only partial
examples and handwaving. They had no theory or models to inform or back up
their assetions.

The code in this project allows a programmer to simulate the spread of network
worms under various circumstances. The code assumes a simple network with numerical
addresses. Not all addresses have functioning machines, similar to the real Internet.
The code also assumes a fully connected Internet, with every machine able to send
a message to every other machine. Time passes in discrete steps with messages sent
and delivered in the same time step. Each machine can execute once per time step,
sending a message that causes execution in some machine at another address.

Building in "vulnerabilities", and allowing each machine to execute Perl code causes
network worms to fall out of the simulation.

## Motivation

I've wanted to make a standalone project since the mid 80s. By "standalone", I
mean an integration of code, documentation and supporting programs. Such a project
should allow the curious to understand the project, rebuild it, and explore the
subject of the project. NWS has an XHTML file `index.html`, which describes a
system for modeling the spread of network worms. That same system is used to create
the graphs referenced by the XHTML file. The XHTML file explains the example code, and
suggests further experiments.

## Installation

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

### Troubleshooting

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
