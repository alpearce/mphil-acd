This is an example project using minilib-c, a small C library that provides
basic functionality - printf, ctype, stdio (if provided with an appropriate
file backend), stdlib and so on.  C source code is standard C, all the magic
is in the library and makefile.

Note that it relies on several functions in baremetal-lib for I/O and
memory handling, which it is linked with.
