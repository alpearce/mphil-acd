#!/bin/sh
#./sim +trace +cTrace | grep "ALLISON" > output.txt &
time ./sim +trace +cTrace &
sleep 1
cherilibs/trunk/tools/debug/berictl -s /tmp/beri_debug_listen_socket_03377 streamtrace > /dev/null 2>/dev/null
sleep 1

