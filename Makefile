# m68k-linux-gnu-gcc mainrom.c -c -o mainrom.o -nostartfiles -nostdlib
# ./asmx -C 68000 -s9 -l rom.lst -o jrom.o -- rom.asm
# m68k-linux-gnu-ld -T linker.ld mainrom.o jrom.o -o rom.bin
# ./asmx -C 68000 -e -w -b 0 -l build/rom.lst -o build/rom.bin -- src/rom.asm
ifndef ($(PREFIX))
	PREFIX=m68k-linux-gnu-
endif

HOSTCC=gcc
CC=$(PREFIX)gcc
AS=$(PREFIX)as
LD=$(PREFIX)ld
OBJCOPY=$(PREFIX)objcopy
OUTNAME="m68kemu"

all: $(OUTNAME) rom
$(OUTNAME):
	$(HOSTCC) -o build/m68kemu src/m68kemu.c musashi/m68kcpu.o musashi/m68kops.o musashi/m68kdasm.o musashi/softfloat/softfloat.o -Imusashi/ -lm -lSDL2main -lSDL2 -lSDL2_ttf -g
rom:	
	$(AS) -mcpu=68000 src/rom_gas.S -o build/rom_gas.o
	$(LD) build/rom_gas.o -Tsrc/linker.ld -o build/rom.bin
	$(OBJCOPY) -O binary build/rom.bin build/rom.bin
clean:
	rm -r build/