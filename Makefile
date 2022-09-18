ASM 	=	nasm
SRC		=	src
DEST	=	build
CC16	=	/usr/bin/watcom/binl64/wcc
LD16	=	/usr/bin/watcom/binl64/wlink

all: structure build floppy run clean
build: bootloader kernel
bootloader: stage1 stage2

structure:
	mkdir -p $(DEST)/bootloader
	mkdir $(DEST)/kernel

stage1:
	$(MAKE) -C $(SRC)/bootloader/stage1 DEST=$(abspath $(DEST))

stage2:
	$(MAKE) -C $(SRC)/bootloader/stage2 DEST=$(abspath $(DEST))

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