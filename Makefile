ASM = nasm
SRC_DIR = src
DEST_DIR = build
 
all: compile floppy run clean

compile:
	mkdir $(DEST_DIR)
	$(ASM) -f bin $(SRC_DIR)/boot.asm -o $(DEST_DIR)/boot.bin
	$(ASM) -f bin $(SRC_DIR)/kernel.asm -o $(DEST_DIR)/kernel.bin

floppy:
	dd if=/dev/zero of=$(DEST_DIR)/floppy.img bs=512 count=2880
	sudo mkfs.fat -F 12 -n "L9" $(DEST_DIR)/floppy.img
	dd if=$(DEST_DIR)/boot.bin of=$(DEST_DIR)/floppy.img conv=notrunc
	mcopy -i $(DEST_DIR)/floppy.img $(DEST_DIR)/kernel.bin "::kernel.bin"
	mcopy -i $(DEST_DIR)/floppy.img img/test.txt "::test.txt"

run:
	qemu-system-x86_64 -drive file=$(DEST_DIR)/floppy.img,if=floppy,format=raw
 
clean:
	rm -r $(DEST_DIR)