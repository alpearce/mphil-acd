__stack_size__ = 0x400; /* 1k stack */
__mem_top__ = 0x9800000040007F00;

__sp = __mem_top__;
__heap_top__ = __mem_top__ - __stack_size__;
__sp_bottom = __heap_top__;

ENTRY(Startup)

SECTIONS
{
. = 0x9800000040000000;	/* BRAM address */

.text : { init.o(.text) 
	*(EXCLUDE_FILE (init.o) .text) }
.bss : { *(.bss) }
.data : { *(.data)}

__heap = ALIGN(0x8); /*64-bit alligned heap pointer */
__bss_start = ADDR(.bss);
__bss_end = ALIGN(__bss_start + SIZEOF(.bss), 0x8);
}

