# m68kpc
 M68K Homebrew computer
# About
  M68KPC Based on Musashi emulator and currently implements following:
 ## DMA
  Direct Memory Access implements 64k of maximum size and 4GB of addressable memory location
 ## IDE
  IDE Controller implements hdd read and write using direct access to controller or using DMA
 ## Video controller
  Video controller implements 320x240 1 bit color framebuffer
 ## Timer
  Timer implements 16 bit count register and interrupt support
 ## IRQ controller
  IRQ Controller implements 8 IRQ's

# Memory map
 ## Main Memory map:
  0x00000000-0x00400000: RAM<br />
  0x000fffff-0x00f00000: ISA bus<br />
 ## ISA Memory map:
  |0| 0x00000-0x12c00: Video controller<br />
  |1| 0x00000-0x00002: Timer<br />
  |2| 0x00000-0x00004: IDE controller<br />
  |3| 0x00000-0x00008: DMA controller<br />
  |4| 0x00000-0x00004: IRQ Controller<br />
