.long   0x00470000      | Initial stack pointer value
.long   EntryPoint      | Start of program
.long   Exception       | Bus error
.long   Exception       | Address error
.long   Exception       | Illegal instruction
.long   Exception       | Division by zero
.long   Exception       | CHK exception
.long   Exception       | TRAPV exception
.long   Exception       | Privilege violation
.long   Exception       | TRACE exception
.long   Exception       | Line-A emulator
.long   Exception       | Line-F emulator
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Spurious exception
.long   Exception       | IRQ level 1
.long   Exception       | IRQ level 2
.long   DMAdone		    | IRQ level 3 (DMA)
.long   Exception       | IRQ level 4
.long   Exception       | IRQ level 5
.long   Exception       | IRQ level 6
.long   Exception       | IRQ level 7
.long   ROMcall         | TRAP #00 exception (ROM calls)
.long   Exception       | TRAP #01 exception
.long   Exception       | TRAP #02 exception
.long   Exception       | TRAP #03 exception
.long   Exception       | TRAP #04 exception
.long   Exception       | TRAP #05 exception
.long   Exception       | TRAP #06 exception
.long   Exception       | TRAP #07 exception
.long   Exception       | TRAP #08 exception
.long   Exception       | TRAP #09 exception
.long   Exception       | TRAP #10 exception
.long   Exception       | TRAP #11 exception
.long   Exception       | TRAP #12 exception
.long   Exception       | TRAP #13 exception
.long   Exception       | TRAP #14 exception
.long   Exception       | TRAP #15 exception
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)
.long   Exception       | Unused (reserved)

.section .text
EntryPoint:           | Entry point address set in ROM header

| ************************************
| Test reset button
| ************************************
jmp Main
| ************************************
| Main
| ************************************
Main:
    lea ver,%a1
    bsr Printstring
    bsr ClearIRQmask
    move.l #0,%d1
    move.l #0,%d2
    move.l #0,%d3
clsscr:
    bsr Drawscreen
    addq.l #1,%d1
    cmpi.l #320,%d1
    beq clsscr2
    cmpi.l #240,%d2
    bne clsscr
    move.l #0,%d6
    move.l #150,%d1
    move.l #105,%d2
    lea tux,%a4
loop:
    move.l (%a4),%d3
    bsr Drawscreen
    addq.l #4,%a4
    addq.l #1,%d1
    cmpi.w #165,%d1
    beq loop2
    cmpi.w #115,%d2
    ble loop
    move.l #0,%d1
    bsr Selectdisk
    move.l #0x000000,%a1
    bsr Setaddressdisk
    move.l #0x0,%d1
    move.l #0x80000,%a1
    move.l #0x200,%d2
    bsr ReadDMA
    lea pcdesc,%a1
    move.l #0x80004,%a0
    move.l (%a0),%a2
    move.l %a2,%a0
    jmp (%a0)
loop2:
    addq.l #1,%d2
    move.l #150,%d1
    jmp loop
clsscr2:
    addq.l #1,%d2
    move.l #0,%d1
    jmp clsscr

Printchar: | %d1 character
    move.w #0x5000,%a0
    move.b %d1,(%a0)
    rts

Printstring: | %a1 string address
    move.b (%a1),%d1
    bsr Printchar
    move.l %a1,%d2
    addq.b #1,%d2
    move.l %d2,%a1
    tst.b (%a1)
    bne Printstring
    rts

Drawscreen: | %d1 x %d2 y %d3 color
    move.l #0xf00000,%a0
    move.l #0x0fffff,%a1
    move.l #0,%d7
    move.b %d7,(%a1)
    move.l #960,%d4
    mulu.w %d2,%d4
    move.l #3,%d6
    mulu.w %d1,%d6
    add.l %d6,%d4
    move.l %a0,%d5
    add.l %d5,%d4
    move.l %d4,%a2
    move.l %d3,%d6
    move.b %d6,(%a2)
    move.l %a2,%d4
    addq.l #1,%d4
    move.l %d4,%a2
    lsr.l #8,%d6
    move.b %d6,(%a2)
    move.l %a2,%d4
    addq.l #1,%d4
    move.l %d4,%a2
    move.l %d3,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    move.b %d6,(%a2)
    rts

Readtimer: | %d1 ret value
    move.l #0xf00000,%a0
    move.l #0x0fffff,%a1
    move.l #1,%d7
    move.b %d7,(%a1)
    move.b (%a0),%d1

Writetimer: | %d1 input value
    move.l #0xf00000,%a0
    move.l #0x0fffff,%a1
    move.l #1,%d7
    move.b %d7,(%a1)
    move.b %d1,(%a0)

itoa: | %d1 input value %a1 string address %d2 base
    cmpi.l #0,%d1
    bne itoamain
    move.l %a1,%d3
    move.b #'0',%d3
    addq.l #1,%d3
    move.b #0,%d3
    rts
itoamain:
    move.l %d3,-(%sp)
    divu.w %d1,%d3
    move.l %d3,%d4
    lsr #8,%d3
    lsr #8,%d3
    andi.l #0xffff,%d4
    move.w %d4,%d1
    cmpi.w #9,%d3
    bgt itoaadd
    add.w #'0',%d3
    jmp itoacon
itoaadd:
    sub.w #10,%d3
    add.w #'a',%d3
itoacon:
    move.l %d3,%d4
    move.l (%sp)+,%a1
    move.b %d4,(%a1)
    move.l %a1,%d3
    addq.l #1,%d3
    cmpi #0,%d1
    bne itoamain
    rts

Selectdisk: | %d1 disk selection (master-slave)
    move.l #0xf00005,%a0
    move.l #0x0fffff,%a2
    move.l #2,%d7
    move.b %d7,(%a2)
    move.b %d1,(%a0)
    rts

Setaddressdisk: | %a1 disk address
    move.l #0xf00000,%a0
    move.l #0x0fffff,%a2
    move.l #2,%d7
    move.b %d7,(%a2)
    addq.l #1,%a0
    move.l %a1,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    subq.l #4,%a0
    rts

Writedisk: | %d1 data %a1 disk address
    move.l #0xf00000,%a0
    move.l #0x0fffff,%a2
    move.l #2,%d7
    move.b %d7,(%a2)
    addq.l #1,%a0
    move.l %a1,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    subq.l #4,%a0
    move.b %d1,(%a0)
    rts

Readdisk: | %d1 data %a1 disk address
    move.l #0xf00000,%a0
    move.l #0x0fffff,%a2
    move.l #2,%d7
    move.b %d7,(%a2)
    addq.l #1,%a0
    move.l %a1,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    subq.l #4,%a0
    move.b (%a0),%d1
    rts

IsreadyDMA: | %d0 return value
    move.l #0xf00008,%a0
    move.l #0x0fffff,%a2
    move.l #3,%d7
    move.b %d7,(%a2)
    move.b (%a0),%d0
    lsr.l #7,%d0
    rts

WriteDMA: | %d1 DMA channel (0-4) %a1 address from write %d2 size
    bsr IsreadyDMA
    tst %d0
    beq DMAret
    move.l #0xf00000,%a0
    move.l #0x0fffff,%a2
    move.l #3,%d7
    move.b %d7,(%a2)
    addq.l #1,%a0
    move.l %a1,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %d2,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %d2,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %d2,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.b %d1,(%a0)
    subq.l #7,%a0
    move.b #1,(%a0)
    rts

ReadDMA: | %d1 DMA channel (0-4) %a1 address from read %d2 size
    bsr IsreadyDMA
    tst %d0
    beq DMAret
    move.l #0xf00000,%a0
    move.l #0x0fffff,%a2
    move.l #3,%d7
    move.b %d7,(%a2)
    addq.l #1,%a0
    move.l %a1,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %a1,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %d2,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %d2,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.l %d2,%d6
    lsr.l #8,%d6
    andi.l #0xff,%d6
    move.b %d6,(%a0)
    addq.l #1,%a0
    move.b %d1,(%a0)
    subq.l #7,%a0
    move.b #0,(%a0)
    rts

DMAret:
    rts

DMAdone:
    bsr IsreadyDMA
    cmpi.b #0x80,%d0
    rte

ClearIRQmask:
    move.l #0xf00002,%a0
    move.l #0x0fffff,%a2
    move.l #4,%d7
    move.b %d7,(%a2)
    move.b #0,(%a0)
    rts

SetIRQmask:
    move.l #0xf00002,%a0
    move.l #0x0fffff,%a2
    move.l #4,%d7
    move.b %d7,(%a2)
    move.b #0xff,(%a0)
    rts

SetIRQbit: | %d1 bits number (0 - 7)
    move.l #0xf00002,%a0
    move.l #0x0fffff,%a2
    move.l #4,%d7
    move.b %d7,(%a2)
    move.b (%a0),%d0
    or.b %d1,%d0
    move.b %d1,(%a0)
    rts

ClearIRQbit: | %d1 bits number (0 - 7)
    move.l #0xf00002,%a0
    move.l #0x0fffff,%a2
    move.l #4,%d7
    move.b %d7,(%a2)
    move.b (%a0),%d0
    eor.b %d1,%d1
    and.b %d1,%d0
    move.b %d1,(%a0)
    rts

ReadKBkey: | %d1 return key
    move.l #0xf00000,%a0
    move.l #0x0fffff,%a2
    move.l #5,%d7
    move.b %d7,(%a2)
    move.b (%a0),%d1
    rts

ReadKBstatus: | %d1 return status
    move.l #0xf00001,%a0
    move.l #0x0fffff,%a2
    move.l #5,%d7
    move.b %d7,(%a2)
    move.b (%a0),%d1
    rts

IskeypressedKB: | %d1 return value
    move.l #0xf00001,%a0
    move.l #0x0fffff,%a2
    move.l #5,%d7
    move.b %d7,(%a2)
    move.b (%a0),%d1
    lsr.l #7,%d1
    rts

Exception:
    rte

ROMcall: | %d7 syscall number
    cmpi.b #0,%d7
    bsr Printchar
    cmpi.b #1,%d7
    bsr Drawscreen
    cmpi.b #2,%d7
    bsr Writedisk
    cmpi.b #3,%d7
    bsr Readdisk
    cmpi.b #4,%d7
    bsr Selectdisk
    cmpi #5,%d7
    bsr Setaddressdisk
    cmpi.b #6,%d7
    bsr WriteDMA
    cmpi.b #7,%d7
    bsr ReadDMA
    cmpi.b #8,%d7
    bsr ReadKBkey
    cmpi.b #9,%d7
    bsr Readtimer
    rte

.section .rodata
tux:
.long 0, 0, 0x0000ff, 0x0000ff, 0, 0, 0, 0, 0, 0, 0, 0x0000ff, 0x0000ff, 0, 0
.long 0, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0, 0, 0, 0, 0, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0
.long 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0, 0, 0, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff
.long 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0, 0, 0, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff
.long 0, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0
.long 0, 0, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0, 0
.long 0, 0, 0, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0, 0, 0
.long 0, 0, 0, 0, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0, 0, 0, 0
.long 0, 0, 0, 0, 0, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0, 0, 0, 0, 0
.long 0, 0, 0, 0, 0, 0, 0x0000ff, 0x0000ff, 0x0000ff, 0, 0, 0, 0, 0, 0
.long 0, 0, 0, 0, 0, 0, 0, 0x0000ff, 0, 0, 0, 0, 0, 0, 0
.align 8
ver: 
.asciz "ROM version 0.02\n"
exceptioncaught:
.asciz "Exception caught!\n"
pcdesc:
.asciz "m68kpc" | computer model
.asciz "68000" | processor type
.long 4194304 | mem size
.long 0x5000 | debug UART address
.byte 1 | dma present
.byte 1 | hard disks present
.byte 0 | floppy present
.byte 1 | keyboard present
.byte 1 | screen present
.byte 1 | timer present
