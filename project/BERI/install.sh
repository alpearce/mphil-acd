#!/bin/sh
# Copyright (c) 2011 Wojciech A. Koszek <wkoszek@FreeBSD.org>
# All rights reserved.
# 
# This software was developed by SRI International and the University of
# Cambridge Computer Laboratory under DARPA/AFRL contract (FA8750-10-C-0237)
# ("CTSRD"), as part of the DARPA CRASH research programme.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# CHERI install script
#
# Requires root priviledges to perform:
#
# 	cp tools/altera.rules in /etc/udev/rules.d
#
# and to run:
#
#	udevadm control --reload-rules
#
UID="`id -u`"

HAS_UDEVD=0
which udevd > /dev/null;
if [ $? -eq 0 ]; then
	HAS_UDEVD=1
fi

HAS_UDEVADM=0
which udevadm > /dev/null;
if [ $? -eq 0 ]; then
	HAS_UDEVADM=1
fi

if [ $HAS_UDEVD -eq 0 ] || [ $HAS_UDEVADM -eq 0 ]; then
	echo "install.sh requires udevd(8) and udevadm(8) to be present";
	echo "Try: sudo apt-get install udev!";
	exit 1;
fi

UDEVD_RUNNING=0
pgrep udevd > /dev/null;
if [ $? -ne 0 ]; then
	echo "install.sh requires udevd(8) to be running";
	echo "Try: /dev/init.d/udev start";
	exit 1;
fi

if [ ! -e /etc/udev/rules.d ]; then
	echo "install.sh expected /etc/udev/rules.d to exist, but it doesn't";
	echo "(not running Ubuntu?)";
	exit 1;
fi

if [ "$UID" != "0" ]; then
	echo "install.sh requires root priviledges to setup the system";
	echo "Try: sudo sh install.sh";
	exit 1;
fi

mkdir -p -m 0755 /usr/share/altera
cp tools/altera.sh /usr/share/altera
cp tools/altera.rules /etc/udev/rules.d/ && udevadm control --reload-rules
if [ $? -ne 0 ]; then
	echo "Problem experienced during the configuration!";
	echo "Your instalation may not be complete!";
	exit 1;
fi

cat <<EOF
-----------------------------------------------------------------------------
Congratulations!

New files necessary to detect Altera DE4/DE2-70 boards has been installed in:

                   /usr/share/altera/altera.sh
                   /etc/udev/rules.d/altera.rules

Your system should be now ready for trying out CHERI.

Please physically disconnect and connect back to your computer the USB cable.
Powering the board on/off doesn't work. You must reconnect the cable by hand.

Good luck!
CHERI team
-----------------------------------------------------------------------------
EOF

