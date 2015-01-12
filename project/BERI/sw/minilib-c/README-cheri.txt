This is minilib-c from
http://code.google.com/p/minilib-c/

It contains basic libc functions such as stdio, stdlib and ctype, and it's
much more lightweight than alleged 'light' libraries like newlib or uclibc.

To build:
$ cd build/cheri/GCC
$ make

Look in lib/misc.c and syscall_template/syscalls.c for the interface to I/O
devices necessary to implement file and console I/O.  cheri-io.c (not part
of the library) implements a basic JTAG UART stdout stream.  cheri-io.c uses
CHERI-specific instructions so needs a two-pass compilation with a
CHERI-enabled assembler. arch/mips64 contains some platform specific
code such as the memory management and syscall support.

In addition you'll require init.s as the entry code..

To compile and link with the library
$ sde-gcc -isystem minilib-c/include -nostdinc -fno-builtin -S -o example.s example.c
$ mips64-as -o example.o example.s
$ sde-gcc -isystem minilib-c/include -nostdinc -fno-builtin -S -o cheri-io.s cheri-io.c
$ mips64-as -o cheri-io.o cheri-io.s
$ mips64-as -o init.o init.s
$ sde-gcc -fno-builtin -L minilib-c/lib/cheri -o example.elf example.o init.o cheri-io.o -lmini


Claims to be under the 3-clause BSD licence but, for example stdio/printf.c
is found variously around the net claiming to the BSD or LGPL.


Theo Markettos
theo.markettos@cl.cam.ac.uk
