#
# CHERI init.s
#
# Bits within this file get started first.
#
# Content of this file will be present in FPGA's BRAM located at 0x4000_0000.
# This file assumes that memory available under 0x9000_0000_0000_0000 is
# uncached.
# 

.set mips64
.set noreorder
.set nobopt
.set noat

        .section ".text"
        .align  2

        .global Startup
        .type   Startup, %function

Startup:
		dla $sp, __sp			# Setup stack to the address configured in the linker script.
						# ld(1) takes care of inserting additional instructions
						# before startMain gets going in order to make sp = __sp
startMain:
		daddu 	$sp, $sp, -32		# Allocate 32 bytes of stack space
		
		dla	$k0, runcached
		jr	$k0
		nop
runcached:
		jal main
		nop
		mtc0 $at, $23

end:
		b end
		nop

