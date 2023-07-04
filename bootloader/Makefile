GCC       ?= x86_64-w64-mingw32-gcc
CFLAGS	  ?= -I/usr/share/gnu-efi/inc -I/usr/share/gnu-efi/inc/x86_64 -I/usr/share/gnu-efi/inc/protocol -ffreestanding -fpic -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -c
LDFLAGS	  ?= -nostdlib -Wl,-dll -shared -Wl,--subsystem,10 -e efi_main


SRC_DIR    = src
GNU_DIR   ?= gnu-efi
BUILD_DIR ?= build

.PHONY: all bootloader always clean

#
#	All
# Make all targets
#
all: bootloader

#
#	Bootloader
# Compile the bootloader
#
bootloader: $(BUILD_DIR)/BOOTx64.EFI
$(BUILD_DIR)/BOOTx64.EFI: always
	$(GCC) $(CFLAGS) -o $(BUILD_DIR)/bootloader/main.o $(SRC_DIR)/main.c
	$(GCC) $(CFLAGS) -o $(BUILD_DIR)/bootloader/data.o $(GNU_DIR)/lib/data.c

	$(GCC) $(LDFLAGS) -o $(BUILD_DIR)/BOOTx64.EFI $(BUILD_DIR)/bootloader/main.o $(BUILD_DIR)/bootloader/data.o

#
#	Always
# Should always be ran while compiling
#
always:
	mkdir -p $(BUILD_DIR)/bootloader

#
# 	Clean
# Clean up the build files
#
clean: 
	rm -f $(BUILD_DIR)/main.o
	rm -f $(BUILD_DIR)/data.o
	rm -f $(BUILD_DIR)/BOOTx64.EFI
