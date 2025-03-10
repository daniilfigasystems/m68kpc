# m68k-linux-gnu-gcc mainrom.c -c -o mainrom.o -nostartfiles -nostdlib
# ./asmx -C 68000 -s9 -l rom.lst -o jrom.o -- rom.asm
# m68k-linux-gnu-ld -T linker.ld mainrom.o jrom.o -o rom.bin
# ./asmx -C 68000 -e -w -b 0 -l build/rom.lst -o build/rom.bin -- src/rom.asm
all:
	gcc -o build/m68kemu src/m68kemu.c musashi/m68kcpu.o musashi/m68kops.o musashi/m68kdasm.o musashi/softfloat/softfloat.o -Imusashi/ -lm -lSDL2main -lSDL2 -lSDL2_ttf -g
	m68k-linux-gnu-as src/rom_gas.S -o build/rom_gas.o
	m68k-linux-gnu-ld build/rom_gas.o -Tsrc/linker.ld -o build/rom.bin
	m68k-linux-gnu-objcopy -O binary build/rom.bin build/rom.bin
clean:
	rm -r build/