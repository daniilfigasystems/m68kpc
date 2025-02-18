# m68k-linux-gnu-gcc mainrom.c -c -o mainrom.o -nostartfiles -nostdlib
# ./asmx -C 68000 -s9 -l rom.lst -o jrom.o -- rom.asm
# m68k-linux-gnu-ld -T linker.ld mainrom.o jrom.o -o rom.bin
all:
	gcc -o build/m68kemu src/m68kemu.c musashi/m68kcpu.o musashi/m68kops.o musashi/m68kdasm.o musashi/softfloat/softfloat.o -Imusashi/ -lm -lSDL2main -lSDL2 -lSDL2_ttf -g
	./asmx -C 68000 -e -w -b 0 -l build/rom.lst -o build/rom.bin -- src/rom.asm
clean:
	rm -r build/