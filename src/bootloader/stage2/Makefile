ASM		?=	nasm
DEST	?=	build
CC16	?=	/usr/bin/watcom/binl64/wcc
LD16	?=	/usr/bin/watcom/binl64/wlink

ASMFLAGS	?=-f obj
CFLAGS16	?=-4 -d3 -s -wx -ms -zl -zq
LDFLAGS16	?=

SOURCES_C	=	$(wildcard *.c)
SOURCES_ASM =	$(wildcard *.asm)
OBJECTS_C	=	$(patsubst %.c, $(DEST)/bootloader/%.obj, $(SOURCES_C))
OBJECTS_ASM	=	$(patsubst %.asm, $(DEST)/bootloader/%.obj, $(SOURCES_ASM))

.PHONY: all clean stage2

all: stage2
stage2: $(DEST)/bootloader/stage2.bin

$(DEST)/bootloader/stage2.bin: $(OBJECTS_ASM) $(OBJECTS_C)
	$(LD16) NAME $(DEST)/stage2.bin FILE \{ $(OBJECTS_ASM) $(OBJECTS_C) \} OPTION MAP=$(DEST)/stage2.map @linker.lnk

$(DEST)/bootloader/%.obj: %.c
	$(CC16) $(CFLAGS16) -fo=$@ $<

$(DEST)/bootloader/%.obj: %.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

