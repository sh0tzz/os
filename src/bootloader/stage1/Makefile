ASM			?=nasm
DEST		?=build
ASMFLAGS	?=-f bin

.PHONY: all

all: stage1
stage1: $(DEST)/bootloader/stage1.bin

$(DEST)/bootloader/stage1.bin:  
	$(ASM) $(ASMFLAGS) stage1.asm -o $(DEST)/bootloader/stage1.bin
