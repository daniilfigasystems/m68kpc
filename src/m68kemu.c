unsigned int  m68k_read_memory_8(unsigned int address);
unsigned int  m68k_read_memory_16(unsigned int address);
unsigned int  m68k_read_memory_32(unsigned int address);
unsigned int  m68k_read_disassembler_8(unsigned int address);
unsigned int  m68k_read_disassembler_16(unsigned int address);
unsigned int  m68k_read_disassembler_32(unsigned int address);
void m68k_write_memory_8(unsigned int address, unsigned int value);
void m68k_write_memory_16(unsigned int address, unsigned int value);
void m68k_write_memory_32(unsigned int address, unsigned int value);
unsigned int kb_read_8(unsigned int address);
void kb_write_8(unsigned int address, unsigned int value);
unsigned int ic_read_8(unsigned int address);
void ic_write_8(unsigned int address, unsigned int value);
void ic_update();
void ic_register();
void ic_set(unsigned char irq);
void ic_clear(unsigned char irq);
unsigned int dma_read_8(unsigned int address);
void dma_write_8(unsigned int address, unsigned int value);
void dma_register();
unsigned int ide_read_8(unsigned int address);
void ide_write_8(unsigned int address, unsigned int value);
void ide_register();
void ide_exit();
void ide_dma_transfer(unsigned int address, unsigned int size, unsigned char rw);
unsigned int timer_read_8(unsigned int address);
void timer_write_8(unsigned int address, unsigned int value);
void timer_update();
void video_write_8(unsigned int vaddr, unsigned int value);
void video_update();
void video_register();
void video_exit();
unsigned int isa_bus_read_8(unsigned int address, unsigned char isel);
void isa_bus_write_8(unsigned int address, unsigned int value, unsigned char isel);
void isa_bus_update();

#define READ_BYTE(BASE, ADDR) (BASE)[ADDR]
#define READ_WORD(BASE, ADDR) (((BASE)[ADDR]<<8) |			\
							  (BASE)[(ADDR)+1])
#define READ_LONG(BASE, ADDR) (((BASE)[ADDR]<<24) |			\
							  ((BASE)[(ADDR)+1]<<16) |		\
							  ((BASE)[(ADDR)+2]<<8) |		\
							  (BASE)[(ADDR)+3])

#define WRITE_BYTE(BASE, ADDR, VAL) (BASE)[ADDR] = (VAL)&0xff
#define WRITE_WORD(BASE, ADDR, VAL) (BASE)[ADDR] = ((VAL)>>8) & 0xff;		\
									(BASE)[(ADDR)+1] = (VAL)&0xff
#define WRITE_LONG(BASE, ADDR, VAL) (BASE)[ADDR] = ((VAL)>>24) & 0xff;		\
									(BASE)[(ADDR)+1] = ((VAL)>>16)&0xff;	\
									(BASE)[(ADDR)+2] = ((VAL)>>8)&0xff;		\
									(BASE)[(ADDR)+3] = (VAL)&0xff

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <SDL2/SDL.h>
#include "m68k.h"

#define ROM_START (0x0000)
#define ROM_SIZE (1024 * 512)
#define ROM_END (ROM_START + ROM_SIZE)
#define MEM_START (ROM_END + 1)
#define MEM_SIZE (1024 * 1024 * 4)
#define MEM_END (MEM_START + MEM_SIZE)
#define ISA_BUS_SIZE (1024 * 1024 * 1)
#define ISA_BUS_OFS 0xf00000
#define ISA_BUS_SELOFS 0x0fffff
#define ISA_BUS_COUNT 16
#define ISA_DEVICES_COUNT 6

unsigned int stop = 0;
FILE *hddfile, *hddfile1;
unsigned char *mem, *vmem, *rom;
SDL_Window *window;
SDL_Renderer *renderer;
struct kb_register
{
    unsigned char KBKEY;
    unsigned char STATUS;
} kb_reg;

struct irq_register
{
    unsigned char IRQPD;
    unsigned char IRQHIGHEST;
    unsigned char IRQMASK;
} irq_reg;

struct dma_register
{
    void (*dmafuncs[4])(unsigned int address, unsigned int size, unsigned char rw);
    unsigned char DMASEL;
    unsigned short ADDRL;
    unsigned short ADDRH;
    unsigned short SIZE;
    unsigned char STATUS;
} dma_reg;

struct ide_register
{
    unsigned char IDESEL : 1;
    unsigned short DL;
    unsigned short DH;
} ide_reg;

struct timer_register
{
    unsigned short timercount;
    unsigned char TL;
    unsigned char TH;
} timer_reg;

struct
{
    unsigned int (*readfuncs[16])(unsigned int address);
    void (*writefuncs[16])(unsigned int address, unsigned int value);
    void (*updatefuncs[16])();
    void (*exitfuncs[16])();
    unsigned char sel;
} isa_bus;

struct 
{
    char *name;
    unsigned int address;
    unsigned int size;
    unsigned int id : 4;
    unsigned char irq : 3;
    unsigned char dma : 2;
    unsigned int (*readfunc)(unsigned int);
    void (*writefunc)(unsigned int, unsigned int);
    void (*updatefunc)();
    void (*registerfunc)();
    void (*exitfunc)();
    void (*dmafunc)(unsigned int, unsigned int, unsigned char);
} isa_desc[ISA_DEVICES_COUNT] =
{
    {
        .name = "Video card",
        .address = 0x00000,
        .size = 0x12c00,
        .id = 0,
        .writefunc = video_write_8,
        .updatefunc = video_update,
        .registerfunc = video_register,
        .exitfunc = video_exit,
    },

    {
        .name = "Timer",
        .address = 0x00000,
        .size = 0x02,
        .id = 1,
        .irq = 1,
        .readfunc = timer_read_8,
        .writefunc = timer_write_8,
        .updatefunc = timer_update,
    },

    {
        .name = "IDE Controller",
        .address = 0x00000,
        .size = 0x800000,
        .id = 2,
        .irq = 2,
        .dma = 1,
        .readfunc = ide_read_8,
        .writefunc = ide_write_8,
        .registerfunc = ide_register,
        .exitfunc = ide_exit,
        .dmafunc = ide_dma_transfer,
    },

    {
        .name = "DMA Controller",
        .address = 0x00000,
        .size = 0x10000,
        .id = 3,
        .irq = 3,
        .readfunc = dma_read_8,
        .writefunc = dma_write_8,
        .registerfunc = dma_register,
    },

    {
        .name = "Interrupt Controller",
        .address = 0x00000,
        .size = 0x04,
        .id = 4,
        .readfunc = ic_read_8,
        .writefunc = ic_write_8,
        .updatefunc = ic_update,
        .registerfunc = ic_register,
    },

    {
        .name = "Keyboard Controller",
        .address = 0x00000,
        .size = 0x02,
        .id = 5,
        .irq = 4,
        .readfunc = kb_read_8,
        .writefunc = kb_write_8,
    }
};

unsigned int  m68k_read_memory_8(unsigned int address)
{
    // printf("[rd8] %x\n", address);

    if (address >= ISA_BUS_OFS && address <= ISA_BUS_OFS + ISA_BUS_SIZE)
        return isa_bus_read_8(address, isa_bus.sel & 0xf);
    else if (address >= ROM_START && address <= ROM_END)
        return READ_BYTE(rom, address - ROM_START);
    else if (address >= MEM_START && address <= MEM_END)
        return READ_BYTE(mem, address - MEM_START);
    else
        printf("[rd8] wrong address! (0x%08x)\n", address);
    
    return 0;
}

unsigned int  m68k_read_memory_16(unsigned int address)
{
    // printf("[rd16] %x\n", address);

    if (address >= ROM_START && address <= ROM_END)
    {
        return READ_WORD(rom, address - ROM_START);
    }
    else if (address >= MEM_START && address <= MEM_END)
    {
        return READ_WORD(mem, address - MEM_START);
    }
    else
        printf("[rd16] wrong address! (0x%08x)\n", address);
    
    return 0;
}

unsigned int  m68k_read_memory_32(unsigned int address)
{
    // printf("[rd32] %x\n", address);

    if (address >= ROM_START && address <= ROM_END)
    {
        return READ_LONG(rom, address - ROM_START);
    }
    else if (address >= MEM_START && address <= MEM_END)
    {
        return READ_LONG(mem, address - MEM_START);
    }
    else
        printf("[rd32] wrong address! (0x%08x)\n", address);
    
    return 0;
}

unsigned int  m68k_read_disassembler_8(unsigned int address)
{
    if (address >= ROM_START && address <= ROM_END)
        return READ_BYTE(rom, address - ROM_START);
    else if (address >= MEM_START && address <= MEM_END)
        return READ_BYTE(mem, address - MEM_START);
    else
        printf("[rd8] wrong address! (0x%08x)\n", address);
    
    return 0;
}

unsigned int  m68k_read_disassembler_16(unsigned int address)
{
    // printf("[rd16] %x\n", address);

    if (address >= ROM_START && address <= ROM_END)
    {
        return READ_WORD(rom, address - ROM_START);
    }
    else if (address >= MEM_START && address <= MEM_END)
    {
        return READ_WORD(mem, address - MEM_START);
    }
    else
        printf("[rd16] wrong address! (0x%08x)\n", address);
    
    return 0;
}

unsigned int  m68k_read_disassembler_32(unsigned int address)
{
    // printf("[rd32] %x\n", address);

    if (address >= ROM_START && address <= ROM_END)
    {
        return READ_LONG(rom, address - ROM_START);
    }
    else if (address >= MEM_START && address <= MEM_END)
    {
        return READ_LONG(mem, address - MEM_START);
    }
    else
        printf("[rd32] wrong address! (0x%08x)\n", address);
    
    return 0;
}

void m68k_write_memory_8(unsigned int address, unsigned int value)
{
    if (address >= ISA_BUS_OFS && address <= ISA_BUS_OFS + ISA_BUS_SIZE)
        isa_bus_write_8(address, value, isa_bus.sel & 0xf);
    else if (address == ISA_BUS_SELOFS)
        isa_bus.sel = value & 0xf;
    else if (address == 0x5000)
        printf("%c", value);
    else if (address >= ROM_START && address <= ROM_END)
        printf("[wr8] can't write to rom! (0x%08x)\n", address);
    else if (address >= MEM_START && address <= MEM_END)
        WRITE_BYTE(mem, address - MEM_START, value);
    else
        printf("[wr8] wrong address! (0x%08x)\n", address);

    // printf("[wr8] (0x%08x) = %x\n", address, value);
}

void m68k_write_memory_16(unsigned int address, unsigned int value)
{
    if (address >= ROM_START && address <= ROM_END)
        printf("[wr16] can't write to rom! (0x%08x)\n", address);
    else if (address >= MEM_START && address <= MEM_END)
    {
        WRITE_WORD(mem, address - MEM_START, value);
    }
    else
        printf("[wr16] wrong address! (0x%08x)\n", address);

    // printf("[wr16] %x %x\n", address, value);
}

void m68k_write_memory_32(unsigned int address, unsigned int value)
{
    if (address >= ROM_START && address <= ROM_END)
        printf("[wr32] can't write to rom! (0x%08x)\n", address);
    else if (address >= MEM_START && address <= MEM_END)
    {
        WRITE_LONG(mem, address - MEM_START, value);
    }
    else
        printf("[wr32] wrong address! (0x%08x)\n", address);

    // printf("[wr32] %x %x\n", address, value);
}

unsigned int kb_read_8(unsigned int address)
{
    switch(address)
    {
        case 0x00:
            unsigned char kbkey_old = kb_reg.KBKEY;
            kb_reg.KBKEY = 0;
            return kbkey_old;
        case 0x01:
            return kb_reg.STATUS;
    }

    return 0;
}

void kb_write_8(unsigned int address, unsigned int value)
{
    switch(address)
    {
        case 0x01:
            kb_reg.STATUS ^= (value & 0xf0);
            break;
    }
}

unsigned int ic_read_8(unsigned int address)
{
    switch(address)
    {
        case 0x00:
            return irq_reg.IRQPD;
        case 0x01:
            return irq_reg.IRQHIGHEST;
        case 0x02:
            return irq_reg.IRQMASK;
    }

    return 0;
}

void ic_write_8(unsigned int address, unsigned int value)
{
    switch(address)
    {
        case 0x02:
            irq_reg.IRQMASK = value & 0xff;
            break;
    }
}

void ic_update()
{
    for (unsigned int i = 0; i < 8; i++)
        ic_clear(i);
}

void ic_register()
{
    irq_reg.IRQMASK = 0xff;
}

void ic_set(unsigned char irq)
{
    unsigned char irq_pending_old = irq_reg.IRQPD;

    irq_reg.IRQPD |= (1 << irq);
    irq_reg.IRQPD &= irq_reg.IRQMASK;
    
    if (irq_reg.IRQPD != irq_pending_old && irq > irq_reg.IRQHIGHEST)
    {
        irq_reg.IRQHIGHEST = irq;
        m68k_set_irq(irq_reg.IRQHIGHEST);
    }
}

void ic_clear(unsigned char irq)
{
    irq_reg.IRQPD &= ~(1 << irq);
    irq_reg.IRQPD &= irq_reg.IRQMASK;

    for (irq_reg.IRQHIGHEST = 7; irq_reg.IRQHIGHEST > 0; irq_reg.IRQHIGHEST--)
        if (irq_reg.IRQPD & (1 << irq_reg.IRQHIGHEST))
            break;
    
    m68k_set_irq(irq_reg.IRQHIGHEST);
}

unsigned int dma_read_8(unsigned int address)
{
    switch(address)
    {
        case 0x08:
            return dma_reg.STATUS; 
    }

    return 0;
}

void dma_write_8(unsigned int address, unsigned int value)
{
    printf("DMA write! 0x%05x = %x %x\n", address, value, dma_reg.SIZE);

    switch(address)
    {
        case 0x00:
            printf("executing addr=0x%08x dmasel=%x size=%x\n", (dma_reg.ADDRH << 16) | (dma_reg.ADDRL), dma_reg.DMASEL, dma_reg.SIZE);
            if (dma_reg.dmafuncs[dma_reg.DMASEL])
            {
                dma_reg.STATUS &= ~(1 << 7);
                dma_reg.dmafuncs[dma_reg.DMASEL]((dma_reg.ADDRH << 16) | (dma_reg.ADDRL & 0xffff), dma_reg.SIZE, value & 0x01);
                dma_reg.STATUS |= (1 << 7);
                ic_set(isa_desc[3].irq);
            }
            break;
        case 0x01:
            dma_reg.ADDRL = value & 0xff;
            break;
        case 0x02:
            dma_reg.ADDRL |= (value & 0xff) << 8;
            break;
        case 0x03:
            dma_reg.ADDRH = value & 0xff;
            break;
        case 0x04:
            dma_reg.ADDRH |= (value & 0xff) << 8;
            break;
        case 0x05:
            dma_reg.SIZE = value & 0xff;
            break;
        case 0x06:
            dma_reg.SIZE |= (value & 0xff) << 8;
            break;
        case 0x07:
            dma_reg.DMASEL = value & 0x03;
            break;
    }
}

void dma_register()
{
    for (unsigned int i = 0; i < ISA_DEVICES_COUNT; i++)
    {
        if (isa_desc[i].dmafunc)
            dma_reg.dmafuncs[isa_desc[i].dma - 1] = isa_desc[i].dmafunc;
    }
    dma_reg.STATUS |= (1 << 7);
}

unsigned int ide_read_8(unsigned int address)
{
    switch(address)
    {
        case 0x00:
            unsigned char buf;
            FILE *f;
            if (ide_reg.IDESEL & 1)
                f = hddfile1;
            else
                f = hddfile;
            fseek(f, (ide_reg.DH << 16) | (ide_reg.DL & 0xffff), SEEK_SET);
            fread(&buf, sizeof(unsigned char), 1, f);
            return buf;
        case 0x05:
            return ide_reg.IDESEL;
    }

    return 0;
}
void ide_write_8(unsigned int address, unsigned int value)
{
    // printf("IDE write! 0x%05x = %x\n", address, value);

    switch(address)
    {
        case 0x00:
            unsigned char buf;
            buf = value & 0xff;
            FILE *f;
            if (ide_reg.IDESEL & 1)
                f = hddfile1;
            else
                f = hddfile;
            fseek(f, (ide_reg.DH << 16) | (ide_reg.DL & 0xffff), SEEK_SET);
            fwrite(&buf, sizeof(unsigned char), 1, f);
            break;
        case 0x01:
            ide_reg.DL = value & 0xff;
            break;
        case 0x02:
            ide_reg.DL |= (value & 0xff) << 8;
            break;
        case 0x03:
            ide_reg.DH = value & 0xff;
            break;
        case 0x04:
            ide_reg.DH |= (value & 0xff) << 8;
            break;
        case 0x05:
            ide_reg.IDESEL = value & 0x01;
            break;
    }
}

void ide_register()
{
    hddfile = fopen("hdd.img", "rb+");
    hddfile1 = fopen("hdd1.img", "rb+");
}

void ide_exit()
{
    fclose(hddfile);
    fclose(hddfile1);
}

void ide_dma_transfer(unsigned int address, unsigned int size, unsigned char rw)
{
    printf("dma transfer %x %x\n", rw, size);

    unsigned char value;

    if (rw == 1)
    {
        for (unsigned int i = 0; i < size + 1; i++)
        {
            printf("[IDE] DMA transfer transaction from (0x%08x) to (0x%08x) value=%x rw=%x\n", address + i, (ide_reg.DH << 16) | (ide_reg.DL & 0xffff), mem[address + i], rw);
            value = m68k_read_memory_8(address + i);
            ide_write_8(0, value);
            if (ide_reg.DL >= 65535)
            {
                ide_reg.DH++;
                ide_reg.DL = 0;
            }
            ide_reg.DL++;
        }
    }
    else
    {
        for (unsigned int i = 0; i < size; i++)
        {
            printf("[IDE] DMA transfer transaction from (0x%08x) to (0x%08x) value=%x rw=%x\n", (ide_reg.DH << 16) | (ide_reg.DL & 0xffff), address + i, mem[address + i], rw);
            value = ide_read_8(0);
            m68k_write_memory_8(address + i, value);
            if (ide_reg.DL >= 65535)
            {
                ide_reg.DH++;
                ide_reg.DL = 0;
            }
            ide_reg.DL++;
        }
    }

    printf("[IDE] DMA transfer transaction done. %d bytes transfered\n", size);
}

unsigned int timer_read_8(unsigned int address)
{
    switch(address)
    {
        case 0x0:
            return timer_reg.TH;
        case 0x1:
            return timer_reg.TL;
    }

    return 0;
}

void timer_write_8(unsigned int address, unsigned int value)
{
    switch(address)
    {
        case 0x0:
            timer_reg.TH = value & 0xff;
            break;
        case 0x1:
            timer_reg.TL = value & 0xff;
            break;
    }
}

void timer_update()
{
    timer_reg.timercount++;
    timer_reg.TH = (timer_reg.timercount >> 8) & 0xff;
    timer_reg.TL = timer_reg.timercount & 0xff;
    ic_set(isa_desc[2].irq);
}

void timer_register()
{
    timer_reg.timercount = 0;
}

void video_write_8(unsigned int vaddr, unsigned int value)
{
    // printf("Write video! 0x%05x rgb:%01x%01x%01x xy:%dx%d\n", vaddr, value & 0x04, (value >> 2) & 0x08, (value >> 5) & 0x04, vaddr % 320, vaddr / 240);
    vmem[vaddr] = value & 0xff;
    SDL_SetRenderDrawColor(renderer, (value & 0x01) ? 255 : 0, (value & 0x01) ? 255 : 0, (value & 0x01) ? 255 : 0, (value & 0x01) ? 255 : 0);
    // SDL_SetRenderDrawColor(renderer, (value & 0x04), ((value >> 2) & 0x08), ((value >> 5) & 0x04), 255);
    SDL_RenderDrawPoint(renderer, vaddr % 320, vaddr / 240);
}

void video_update()
{
    SDL_RenderPresent(renderer);
}

void video_register()
{
    vmem = malloc(isa_desc[0].size);
}

void video_exit()
{
    free(vmem);
}

unsigned int isa_bus_read_8(unsigned int address, unsigned char isel)
{
    unsigned char retval = 0;

    retval = isa_bus.readfuncs[isel](address - ISA_BUS_OFS);

    return retval;
}

void isa_bus_write_8(unsigned int address, unsigned int value, unsigned char isel)
{
    // printf("isel %d\n", isel);
    isa_bus.writefuncs[isel](address - ISA_BUS_OFS, value);
}

void isa_bus_update()
{
    for (unsigned int i = 0; i < 16; i++)
    {
        if (isa_bus.updatefuncs[i])
            isa_bus.updatefuncs[i]();
    }
}

void isa_bus_exit()
{
    for (unsigned int i = 0; i < 16; i++)
    {
        if (isa_bus.exitfuncs[i])
            isa_bus.exitfuncs[i]();
    }
}

void m68k_showregs()
{
    char *dregs[8] = {"d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7"};
    char *aregs[8] = {"a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7"};

    for (int i = 0; i < 8; i++)
    {
        printf("%s: 0x%08x\n", dregs[i], m68k_get_reg(NULL, M68K_REG_D0 + i));
    }
    for (int i = 0; i < 8; i++)
    {
        printf("%s: 0x%08x\n", aregs[i], m68k_get_reg(NULL, M68K_REG_A0 + i));
    }
    printf("%06x: ", 0);
    for (int i = 0; i < 512; i++)
    {
        printf("%02x ", mem[i]);
        if (i % 4 == 3 && i != 512-1)
        {
            printf("\n");
            printf("%06x: ", i + 1);
        }
    }
    printf("\n");

    return;
}

void m68k_int_ack(int irq)
{
    printf("ack %d\n", irq);
}

void m68k_fc_call(unsigned int fc)
{

}

void m68k_instr_call(unsigned int pc)
{
    // char buff[128];

    // m68k_disassemble(buff, pc, M68K_CPU_TYPE_68000);
    // printf("0x%08x: %s\n", pc, buff);
}

void disassemble_program()
{
	unsigned int pc;
	unsigned int instr_size;
	char buff[100];
	char buff2[100];

	pc = m68k_read_disassembler_32(4);

	while(pc <= 0x16e)
	{
		instr_size = m68k_disassemble(buff, pc, M68K_CPU_TYPE_68000);
		printf("%03x: %s\n", pc, buff);
		pc += instr_size;
	}
}

void abortex(int sig)
{
    stop = 1;
    disassemble_program();
    m68k_showregs();
    isa_bus_exit();
    exit(0);
}

int main(int argc, char *argv[])
{
    if (argc < 2)
        return -1;

    for (unsigned int i = 0; i < ISA_DEVICES_COUNT; i++)
    {
        if (isa_desc[i].readfunc)
            isa_bus.readfuncs[isa_desc[i].id] = isa_desc[i].readfunc;
        if (isa_desc[i].writefunc)
            isa_bus.writefuncs[isa_desc[i].id] = isa_desc[i].writefunc;
        if (isa_desc[i].updatefunc)
            isa_bus.updatefuncs[isa_desc[i].id] = isa_desc[i].updatefunc;
        if (isa_desc[i].registerfunc)
            isa_desc[i].registerfunc();
        if (isa_desc[i].exitfunc)
            isa_bus.exitfuncs[isa_desc[i].id] = isa_desc[i].exitfunc;
    }
    mem = malloc(MEM_SIZE);
    rom = malloc(ROM_SIZE);
    FILE *f = fopen(argv[1], "rb");
    fseek(f, 0, SEEK_END);
    unsigned int size = ftell(f);
    printf("Size: %d bytes\n", size);
    fseek(f, 0, SEEK_SET);
    fread(rom, sizeof(unsigned char), size, f);
    fclose(f);
    signal(SIGINT, abortex);
    video_register();
    SDL_Init(SDL_INIT_TIMER | SDL_INIT_VIDEO);
    window = SDL_CreateWindow("M68KEmu", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 320 * 3, 240 * 3, 0);
    renderer = SDL_CreateRenderer(window, -1, 0);
    SDL_RenderSetLogicalSize(renderer, 320, 240);
    SDL_Event event;
    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68000);
    m68k_pulse_reset();

    while (!stop)
    {
        m68k_execute(100);
        fflush(stdout);
        while (SDL_PollEvent(&event) == 1) {
            if (event.type == SDL_QUIT) 
            {
                stop = 1;
            }
            else if (event.type == SDL_KEYDOWN) 
            {
                kb_reg.KBKEY = event.key.keysym.sym;
                ic_set(isa_desc[5].irq);
                kb_reg.STATUS |= (1 << 0);
            }
            else if (event.type == SDL_KEYUP) 
            {
                kb_reg.STATUS &= ~(1 << 0);
            }
        }

        isa_bus_update();
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    abortex(0);
}