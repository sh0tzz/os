ASM = nasm
SRC = src
DEST = build

all: structure build floppy run clean
build: bootloader kernel

structure:
	mkdir -p $(DEST)/bootloader
	mkdir $(DEST)/kernel

bootloader:
	$(MAKE) -C $(SRC)/bootloader DEST=$(abspath $(DEST))

kernel:
	$(MAKE) -C $(SRC)/kernel DEST=$(abspath $(DEST))

floppy:
	dd if=/dev/zero of=$(DEST)/floppy.img bs=512 count=2880
	sudo mkfs.fat -F 12 -n "L9" $(DEST)/floppy.img
	dd if=$(DEST)/bootloader/stage1.bin of=$(DEST)/floppy.img conv=notrunc
	mcopy -i $(DEST)/floppy.img $(DEST)/kernel/kernel.bin "::kernel.bin"
	mcopy -i $(DEST)/floppy.img img/test.txt "::test.txt"

run:
	qemu-system-x86_64 -drive file=$(DEST)/floppy.img,if=floppy,format=raw
 
clean:
	rm -r $(DEST)