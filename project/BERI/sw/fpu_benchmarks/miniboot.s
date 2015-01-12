#-
# Copyright (c) 2011-2012 Robert N. M. Watson
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

.set mips64
.set noreorder
.set nobopt
.set noat

#
# "miniboot" micro-loader, which does minimal CPU initialisation and then
# jumps to a plausible kernel start address.
#

		.text
		.global start
		.ent start
start:
		# Set up stack and stack frame
		dla	$fp, __sp
		dla	$sp, __sp
		daddu 	$sp, $sp, -32

		# Switch to 64-bit mode -- no effect on CHERI, but required
		# for gxemul.
		mfc0	$at, $12
		or	$at, $at, 0xe0
		mtc0	$at, $12
		
jump_to_c:
		dla $sp, __sp
        dla $gp, _gp
        # Install exception handlers
        dla $a0, exceptionhandler
        jal bev1_handler_install
        nop        
        jal bev_clear
        nop
        dla $a0, exceptionhandler
        jal bev0_handler_install
        nop
                        
        # Enable CP1
        mfc0 $t0, $12
        dli $t1, 1 << 29
        or $t0, $t0, $t1
        mtc0 $t0, $12
        nop
        nop
        nop
        nop
        nop
		# Jump to main program in C
        dla  $25, main
		jalr $25
		nop
		# Explicitly clear most registers.  $sp, $fp, and $ra aren't
		# cleared as they are part of our initialised stack.
cleanup:
		dli	$at, 0
		dli	$v0, 0
		dli	$v1, 0
		dli	$a4, 0
		dli	$a5, 0
		dli	$a6, 0
		dli	$a7, 0
		dli	$t0, 0
		dli	$t1, 0
		dli	$t2, 0
		dli	$t3, 0
		dli	$s0, 0
		dli	$s1, 0
		dli	$s2, 0
		dli	$s3, 0
		dli	$s4, 0
		dli	$s5, 0
		dli	$s6, 0
		dli	$s7, 0
		dli	$t8, 0
		dli	$t9, 0
		dli	$k0, 0
		dli	$k1, 0
		dli	$gp, 0
		mthi	$at
		mtlo	$at

		.end start

		.data

		# Provide empty argument and environmental variable arrays
arg:		.dword	0x0000000000000000
env:		.dword	0x0000000000000000
