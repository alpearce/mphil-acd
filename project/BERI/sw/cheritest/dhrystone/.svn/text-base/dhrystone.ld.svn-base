/****************************************************************************
* Definition of the base address for all virtual segments
*****************************************************************************/

seg_data_base      = 0x00800000;
seg_code_base      = 0x00400000;

/***************************************************************************
* Grouping sections into segments for code and data
***************************************************************************/

SECTIONS
{
    . = seg_code_base;
    seg_code : 
    {
        *(.text)
    }
    . = seg_data_base;
    seg_data : 
    {
        *(.ctors)
        *(.rodata)
        /* . = ALIGN(4); */
        *(.rodata.*)
        /* . = ALIGN(4); */
        *(.data)
        /* . = ALIGN(4); */
        *(.lit8)
        *(.lit4)
        *(.sdata)
        /* . = ALIGN(4); */
        *(.bss)
        *(COMMON)
        *(.sbss)
        *(.scommon)
    }
}
