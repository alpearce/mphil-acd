#!/bin/sh
rm sim
rm output.txt
make MICRO=1 NOT_FLAT=1 sim
./sim +trace +cTrace > output.txt
perl cpi.pl output.txt
