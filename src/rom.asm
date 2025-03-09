	; ******************************************************************
	; Sega Megadrive ROM header
	; ******************************************************************
	dc.l   $000FF000      ; Initial stack pointer value
	dc.l   EntryPoint      ; Start of program
	dc.l   Exception       ; Bus error
	dc.l   Exception       ; Address error
	dc.l   Exception       ; Illegal instruction
	dc.l   Exception       ; Division by zero
	dc.l   Exception       ; CHK exception
	dc.l   Exception       ; TRAPV exception
	dc.l   Exception       ; Privilege violation
	dc.l   Exception       ; TRACE exception
	dc.l   Exception       ; Line-A emulator
	dc.l   Exception       ; Line-F emulator
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Spurious exception
	dc.l   Exception       ; IRQ level 1
	dc.l   Exception       ; IRQ level 2
	dc.l   DMAdone		   ; IRQ level 3 (DMA)
	dc.l   Exception       ; IRQ level 4
	dc.l   Exception       ; IRQ level 5
	dc.l   Exception       ; IRQ level 6
	dc.l   Exception       ; IRQ level 7
	dc.l   Exception       ; TRAP #00 exception
	dc.l   Exception       ; TRAP #01 exception
	dc.l   Exception       ; TRAP #02 exception
	dc.l   Exception       ; TRAP #03 exception
	dc.l   Exception       ; TRAP #04 exception
	dc.l   Exception       ; TRAP #05 exception
	dc.l   Exception       ; TRAP #06 exception
	dc.l   Exception       ; TRAP #07 exception
	dc.l   Exception       ; TRAP #08 exception
	dc.l   Exception       ; TRAP #09 exception
	dc.l   Exception       ; TRAP #10 exception
	dc.l   Exception       ; TRAP #11 exception
	dc.l   Exception       ; TRAP #12 exception
	dc.l   Exception       ; TRAP #13 exception
	dc.l   Exception       ; TRAP #14 exception
	dc.l   Exception       ; TRAP #15 exception
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)
	dc.l   Exception       ; Unused (reserved)


EntryPoint:           ; Entry point address set in ROM header

; ************************************
; Test reset button
; ************************************
    jmp Main
; ************************************
; Main
; ************************************
Main:
	lea.l ver,a1
	bsr Printstring
	move.b #0,d2
	bsr Selectdisk
	move.l #$80001,a1
	move.b #0,d1
	move.w #$0eff,d2
	bsr ReadDMA
	moveq.l #0,d1
	moveq.l #0,d2
	moveq #1,d3
	move.l #$80001,a1
	move.l (a1),d2
	lea.l pcdesc,a2
	jmp (a1)
	stop #$00

Printchar: ; d1 character
	move.w #$5000,a0
	move.b d1,(a0)
	rts

Printstring: ; a1 string address
	move.b (a1),d1
	bsr Printchar
	move.l a1,d2
	addq.b #1,d2
	move.l d2,a1
	tst.b (a1)
	bne Printstring
	rts

Drawscreen: ; d1 x d2 y d3 color
	move.l #$f00000,a0
	move.l #$0fffff,a1
	moveq.l #0,d7
	move.b d7,(a1)
	move.w #320,d4
	mulu.w d2,d4
	add.w d1,d4
	move.l a0,d5
	add.l d5,d4
	move.l d4,a2
	move.b d3,(a2)
	rts

Readtimer: ; d1 ret value
	move.l #$f00000,a0
	move.l #$0fffff,a1
	moveq.l #1,d7
	move.b d7,(a1)
	move.b (a0),d1

Writetimer: ; d1 input value
	move.l #$f00000,a0
	move.l #$0fffff,a1
	moveq.l #1,d7
	move.b d7,(a1)
	move.b d1,(a0)

itoa: ; d1 input value a1 string address d2 base
	cmpi #0,d1
	bne itoamain
	move.l a1,d3
	move.b #'0',d3
	addq.l #1,d3
	move.b #0,d3
	rts
itoamain:
	move.l d3,-(sp)
	divu d1,d3
	move.l d3,d4
	lsr #8,d3
	lsr #8,d3
	andi.l #$ffff,d4
	move.w d4,d1
	cmpi.w #9,d3
	bgt itoaadd
	add.w #'0',d3
	jmp itoacon
itoaadd:
	sub.w #10,d3
	add.w #'a',d3
itoacon:
	move.l d3,d4
	move.l (sp)+,a1
	move.b d4,(a1)
	move.l a1,d3
	addq.l #1,d3
	cmpi #0,d1
	bne itoamain
	rts

Selectdisk: ; d1 disk selection (master-slave)
	move.l #$f00005,a0
	move.l #$0fffff,a2
	moveq.l #2,d7
	move.b d7,(a2)
	move.b d1,(a0)
	rts

Setaddressdisk: ; a1 disk address
	move.l #$f00000,a0
	move.l #$0fffff,a2
	moveq.l #2,d7
	move.b d7,(a2)
	addq.l #1,a0
	move.l a1,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	lsr.l #8,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	subq.l #4,a0
	rts

Writedisk: ; d1 data a1 disk address
	move.l #$f00000,a0
	move.l #$0fffff,a2
	moveq.l #2,d7
	move.b d7,(a2)
	addq.l #1,a0
	move.l a1,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	lsr.l #8,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	subq.l #4,a0
	move.b d1,(a0)
	rts

Readdisk: ; d1 data a1 disk address
	move.l #$f00000,a0
	move.l #$0fffff,a2
	moveq.l #2,d7
	move.b d7,(a2)
	addq.l #1,a0
	move.l a1,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	lsr.l #8,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	subq.l #4,a0
	move.b (a0),d1
	rts

IsreadyDMA: ; d0 return value
	move.l #$f00008,a0
	move.l #$0fffff,a2
	moveq.l #3,d7
	move.b d7,(a2)
	move.b (a0),d0
	lsr #7,d0
	rts

WriteDMA: ; d1 DMA channel (0-4) a1 address from write d2 size
	bsr IsreadyDMA
	tst d0
	beq DMAret
	move.l #$f00000,a0
	move.l #$0fffff,a2
	moveq.l #3,d7
	move.b d7,(a2)
	addq.l #1,a0
	move.l a1,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l d2,d6
	lsr.l #8,d6
	lsr.l #8,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l d2,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l d2,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.b d1,(a0)
	subq.l #7,a0
	move.b #1,(a0)
	rts

ReadDMA: ; d1 DMA channel (0-4) a1 address from read d2 size
	bsr IsreadyDMA
	tst d0
	beq DMAret
	move.l #$f00000,a0
	move.l #$0fffff,a2
	moveq.l #3,d7
	move.b d7,(a2)
	addq.l #1,a0
	move.l a1,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l a1,d6
	lsr.l #8,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l d2,d6
	lsr.l #8,d6
	lsr.l #8,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l d2,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.l d2,d6
	lsr.l #8,d6
	andi.l #$ff,d6
	move.b d6,(a0)
	addq.l #1,a0
	move.b d1,(a0)
	subq.l #7,a0
	move.b #0,(a0)
	rts

DMAret:
	rts

DMAdone:
	bsr IsreadyDMA
	cmpi.b #$80,d0
	rte

ClearIRQmask:
	move.l #$f00000,a0
	move.l #$0fffff,a2
	moveq.l #4,d7
	move.b d7,(a2)
	move.b #0,(a0)
	rts

SetIRQmask:
	move.l #$f00000,a0
	move.l #$0fffff,a2
	moveq.l #4,d7
	move.b d7,(a2)
	move.b #$ff,(a0)
	rts

SetIRQbit: ; d1 bits number (0 - 7)
	move.l #$f00002,a0
	move.l #$0fffff,a2
	moveq.l #4,d7
	move.b d7,(a2)
	move.b (a0),d0
	or.b d1,d0
	move.b d1,(a0)
	rts
ClearIRQbit: ; d1 bits number (0 - 7)
	move.l #$f00002,a0
	move.l #$0fffff,a2
	moveq.l #4,d7
	move.b d7,(a2)
	move.b (a0),d0
	eor.b d1,d1
	and.b d1,d0
	move.b d1,(a0)
	rts

ReadKBkey: ; d1 return key
	move.l #$f00000,a0
	move.l #$0fffff,a2
	moveq.l #5,d7
	move.b d7,(a2)
	move.b (a0),d1
	rts

Exception:
	rte

ver: 
	dc.b "ROM version 0.02\n",0
exceptioncaught:
	dc.b "Exception caught!\n",0
pcdesc:
	dc.b "m68kpc",0 ; computer model
	dc.b "68000",0 ; processor type
	dc.l 4194304 ; mem size
	dc.l $5000 ; debug UART address
	dc.b 1 ; dma present
	dc.b 1 ; hard disks present
	dc.b 0 ; floppy present
	dc.b 1 ; keyboard present
	dc.b 1 ; screen present
	dc.b 1 ; timer present