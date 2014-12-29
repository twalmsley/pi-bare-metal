ENTRY(_start)
 
SECTIONS
{
    /* Starts at LOADER_ADDR. */
    . = 0x8000;
    __start = .;
    __text_start = .;
    .text :
    {
        KEEP(*(.text.startup))
        KEEP(*(.text.interrupt))
        *(.text)
    }
    . = ALIGN(4);
    __text_end = .;
 
    __rodata_start = .;
    .rodata :
    {
        *(.rodata)
    }
    . = ALIGN(4);
    __rodata_end = .;
 
    __data_start = .;
    .data :
    {
        *(.data)
    }
    . = ALIGN(4);
    __data_end = .;
 
    __bss_start = .;
    .bss :
    {
        bss = .;
        *(.bss)
    }
    . = ALIGN(4);
    __bss_end__ = .;
    __end__ = .;
}
