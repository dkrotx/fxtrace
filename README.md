fxtrace
=======

Trace file access of launching command


PREREQUISITE
============
Linux 2.6+, autoconf, automake, libtool 


INSTALLATION
============
$ autoreconf -fiv
$ ./configure
$ make
$ sudo make install

Alternatively you can do a local installation with:
$ autoreconf -fiv
$ ./configure --prefix=$HOME/local # place your own prefix here
$ make
$ make install


USAGE
=====

- Simple case:
  $ fxtrace --log /tmp/fxtrace.txt cat /etc/fstab

- More advanced case:
  $ fxtrace --log /tmp/fxtrace.txt --mode wsr --prefix $HOME/etc mc

Also, see `fxtrace --help` or `man fxtrace` for more details.
