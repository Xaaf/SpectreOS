ASM=nasm
QEMU=qemu-system-i386

QEMU_FLAGS=-fda

SRC_DIR=src
BUILD_DIR=build

.PHONY: all always clean floppy_image run

all: floppy_image

#
#	Build to Floppy
#
floppy_image: $(BUILD_DIR)/spectre.img
$(BUILD_DIR)/spectre.img: bootloader
	dd if=/dev/zero of=$(BUILD_DIR)/spectre.img bs=512 count=2880
	mkfs.fat -F 12 -n "SPECTRE OS" $(BUILD_DIR)/spectre.img

	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/spectre.img conv=notrunc

#
#	Build Bootloader
#
bootloader: $(BUILD_DIR)/boot.bin
$(BUILD_DIR)/boot.bin: always
	$(ASM) $(SRC_DIR)/boot/boot.asm -f bin -o $(BUILD_DIR)/boot.bin

#
#	Always
#
always:
	mkdir -p $(BUILD_DIR)

#
#	Run
#
run: floppy_image
	$(QEMU) $(QEMU_FLAGS) $(BUILD_DIR)/spectre.img

#
#	Clean
#
clean:
	rm -rf $(BUILD_DIR)
