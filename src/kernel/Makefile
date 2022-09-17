ASM ?= nasm
DEST ?= build

.PHONY: all clean

all: kernel
kernel: $(DEST)/kernel/kernel.bin

$(DEST)/kernel/kernel.bin:
	$(ASM) -f bin kernel.asm -o $(DEST)/kernel/kernel.bin