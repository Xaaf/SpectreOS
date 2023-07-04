GCC        = x86_64-w64-mingw32-gcc
CFLAGS	   = -ffreestanding -I/usr/share/gnu-efi/inc -I/usr/share/gnu-efi/inc/x86_64 -I/usr/share/gnu-efi/inc/protocol -c
LDFLAGS	   = -nostdlib -Wl,-dll -shared -Wl,--subsystem,10 -e efi_main

QEMU       = qemu-system-x86_64
OVMF_DIR   = /usr/share/ovmf/
OVMF	   = ovmf/OVMF.fd

GNU_DIR    = gnu-efi
BUILD_DIR  = build

# Bootloader & Kernel folders
BOOTLOADER = bootloader

.PHONY: all run bootloader fat iso always clean

#
#	All
# Make all targets
#
all: iso

#
#	Run
# Run SpectreOS in qemu
#
run: iso
	$(QEMU) -L $(OVMF_DIR) -pflash $(OVMF) -cdrom $(BUILD_DIR)/spectre.iso

#
#	ISO
# Build the final iso image
#
iso: $(BUILD_DIR)/spectre.iso
$(BUILD_DIR)/spectre.iso: fat
	mkdir -p $(BUILD_DIR)/iso
	cp $(BUILD_DIR)/spectre_fat.img $(BUILD_DIR)/iso/

	xorriso -as mkisofs -R -f -e spectre_fat.img -no-emul-boot -o $(BUILD_DIR)/spectre.iso $(BUILD_DIR)/iso

#
#	FAT
# Create the FAT filesystem
#
fat: $(BUILD_DIR)/spectre_fat.img
$(BUILD_DIR)/spectre_fat.img: bootloader
	dd if=/dev/zero of=$(BUILD_DIR)/spectre_fat.img bs=1k count=1440
	mformat -i $(BUILD_DIR)/spectre_fat.img -f 1440 ::
	mmd -i $(BUILD_DIR)/spectre_fat.img ::/EFI
	mmd -i $(BUILD_DIR)/spectre_fat.img ::/EFI/BOOT
	mcopy -i $(BUILD_DIR)/spectre_fat.img $(BUILD_DIR)/BOOTx64.EFI ::/EFI/BOOT

#
#	Bootloader
# Build the bootloader
#
bootloader: $(BUILD_DIR)/BOOTx64.EFI
$(BUILD_DIR)/BOOTx64.EFI: always
#   $(GCC) $(CFLAGS) -o $(BUILD_DIR)/main.o $(SRC_DIR)/bootloader/main.c
# 	$(GCC) $(CFLAGS) -o $(BUILD_DIR)/data.o $(GNU_DIR)/lib/data.c
	$(MAKE) -C $(BOOTLOADER) GNU_DIR=$(abspath $(GNU_DIR)) BUILD_DIR=$(abspath $(BUILD_DIR))

#	$(GCC) $(LDFLAGS) -o $(BUILD_DIR)/BOOTx64.EFI $(BUILD_DIR)/main.o $(BUILD_DIR)/data.o

#
#	Always
# Should always be ran when compiling
#
always:
	mkdir -p $(BUILD_DIR)

#
#	Clean
# Clean up the build files
#
clean:
	rm -rf $(BUILD_DIR)/*