ASM ?= nasm
DEST ?= build

.PHONY: all clean

all: stage1 stage2
stage1: $(DEST)/bootloader/stage1.bin
stage2: $(DEST)/bootloader/stage2.bin

$(DEST)/bootloader/stage1.bin:
	$(ASM) -f bin stage1.asm -o $(DEST)/bootloader/stage1.bin

$(DEST)/bootloader/stage2.bin:
	$(ASM) -f bin stage2.asm -o $(DEST)/bootloader/stage2.bin