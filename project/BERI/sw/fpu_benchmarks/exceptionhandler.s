        .text
		.global exceptionhandler
		.ent exceptionhandler
exceptionhandler:
        dmfc0 $a0, $14 # Load exception address
        mfc0 $a1, $13 # Load cause register
        dmfc0 $a2, $8 # Load bad virtual address
        # Go the the C code handler
        dla $t0, handle_exception
        jalr $t0
        nop
        # Use return addess from handler
        dmtc0 $v0, $14
        eret
        .end exceptionhandler
