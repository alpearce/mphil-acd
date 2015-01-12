#!/bin/sh

./rawtobdf.pl 6x8.raw
./rawtobdf.pl 8x8.raw
./rawtobdf.pl 8x12.raw

bdftopcf -t cp437-6x8.bdf > cp437-6x8.pcf
bdftopcf -t cp437-8x8.bdf > cp437-8x8.pcf
bdftopcf -t cp437-8x12.bdf > cp437-8x12.pcf

mkfontdir .

