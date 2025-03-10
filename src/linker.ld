MEMORY
{
    ROM (rx) : ORIGIN = 0, LENGTH = 512k
    RAM (wx) : org = 0x00080000, len = 4M
}

SECTIONS
{
    .text : { *(.text); } > ROM
    .rodata : { *(.rodata); } > ROM
}