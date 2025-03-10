# m68kpc
 M68K Homebrew computer
# About
  M68KPC Based on Musashi emulator and currently implements following:
 ## DMA
  Direct Memory Access implements 64k of maximum size and 4GB of addressable memory location
 ## IDE
  IDE Controller implements hdd read and write using direct access to controller or using DMA
 ## Video controller
  Video controller implements 320x240 24 bit color framebuffer
 ## Timer
  Timer implements 16 bit count register and interrupt support
 ## IRQ controller
  IRQ Controller implements 8 IRQ's
 ## Keyboard controller
  Keyboard controller implements read key and status
 ## ISA bus
  ISA bus implements 16 lines addressable up to 1mb

# Memory map
 ## Main Memory map:
 ```
  0x00000000-0x0007ffff: ROM
  0x00080000-0x00480000: RAM
  0x000fffff-0x00f00000: ISA bus
 ```
 ## ISA Memory map:
 ```
  |0| 0x00000-0x12c00: Video controller
  |1| 0x00000-0x00002: Timer
  |2| 0x00000-0x00005: IDE controller
  |3| 0x00000-0x00008: DMA controller
  |4| 0x00000-0x00004: IRQ controller
  |5| 0x00000-0x00002: Keyboard controller
 ```

 # TODO
  - [x] Implement IDE master-slave bus
  - [x] Implement IRQ controller
  - [X] Add Keyboard controller
  - [ ] Implement MMU
