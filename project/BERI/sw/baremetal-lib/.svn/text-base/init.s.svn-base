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

    mfc0 $k0, $12
    li $k1, 0xF0000000
    or $k0, $k0, $k1
    mtc0 $k0, $12
		dla $sp, __sp			# Setup stack to the address configured in the linker script.
						# ld(1) takes care of inserting additional instructions
						# before startMain gets going in order to make sp = __sp
		#
		# Set up exception handler
		#
		jal	bev_clear
		nop
		dla	$a0, common_handler
		jal	bev0_handler_install
		nop
		dla	$a0, common_handler
		jal	set_bev1_common_handler
		nop
		dla	$a0, tlb_handler
		jal	set_bev0_tlb_handler
		nop
		jal	set_bev1_tlb_handler
		nop
		jal	set_bev0_xtlb_handler
		nop
		jal	set_bev1_xtlb_handler
		nop
startMain:
		daddu 	$sp, $sp, -32		# Allocate 32 bytes of stack space
		dla	$k0, runcached
		jr	$k0
		nop
runcached:
    dla $t9, main   # llvm requires the invoked address to be in $t9
		jal $t9
		nop
		mtc0 $at, $23

end:
		b end
		nop

