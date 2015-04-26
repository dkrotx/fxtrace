# fxtrace

Fxtrace is utility for *unpriveleged* tracing file access.

It uses technique of replacing library calls with LD_PRELOAD and may be seen as alternative to strace and auditd.

With some benefits:
- fxtrace does not require root priveleges or even system-wide installation like audit
- it never "lose" events like auditd. Because it behaves like proxy, not as external notification mechanism
- it will not hang your program like strace. Using `strace -f` with complicated programs is usually bad idea
- it almost has not affect speed of IO like audit does.

But also with some limitations:
- fxtrace will not handle statically linked binaries
- it will not "see" direct syscalls e.x. using 'int 0x80'.


## PREREQUISITES

- Linux 2.6+
- autoconf, automake, libtool 


## INSTALLATION

### System-wide installation is usual:
```
$ autoreconf -fiv
$ ./configure
$ make
$ sudo make install
```

### Alternatively you can do a local installation:
```
$ autoreconf -fiv
$ ./configure --prefix=$HOME/local # place your own prefix here
$ make
$ make install
```

## USAGE

### Simple case:
`$ fxtrace --log /tmp/fxtrace.txt cat /etc/fstab`

this will show you, at least /bin/cat and /etc/fstab
  

### More advanced case:
`$ fxtrace --log /tmp/fxtrace.txt --mode wr --prefix $HOME mc`

In this case you will see all files which Midnight Commander read or write within your home directory.

Also, see `fxtrace --help` or `man fxtrace` for more details.

