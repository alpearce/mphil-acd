#!/bin/sh
i=1
while [ $i -le 10 ]
do
    ./berictl streamtrace 256
    #i=`expr $i + 1`
done
