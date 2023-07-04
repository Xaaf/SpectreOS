GNU       ?= /usr/share/gnu-efi

GCC       ?= x86_64-w64-mingw32-gcc
LD        ?= ld

CFLAGS	  ?= -I$(GNU)/inc -I$(GNU)/inc/x86_64 -I$(GNU)/inc/protocol -ffreestanding -fpic -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -c
LDFLAGS	  ?= -shared -Bsymbolic -L$(GNU)/x86_64/lib -L$(GNU)/x86_64/gnuefi -T$(GNU)/gnuefi/elf_x86_64_efi.lds $(GNU)/x86_64/gnuefi/crt0-efi-x86_64.o
OBJCFLAGS ?= -j .text -j .sdata -j .data -j .dynamic -j .dynsym  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10

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
bootloader: $(BUILD_DIR)/boot.efi
$(BUILD_DIR)/boot.efi: always
	$(GCC) $(CFLAGS) -o $(BUILD_DIR)/bootloader/main.o $(SRC_DIR)/main.c

	$(LD) $(LDFLAGS) $(BUILD_DIR)/bootloader/main.o -o $(BUILD_DIR)/bootloader/main.so -lgnuefi -lefi
#	$(GCC) $(LDFLAGS) -o $(BUILD_DIR)/BOOTx64.EFI $(BUILD_DIR)/bootloader/main.o $(BUILD_DIR)/bootloader/data.o

#	objcopy $(OBJCFLAGS) $(BUILD_DIR)/bootloader/main.so $(BUILD_DIR)/boot.efi

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
	rm -rf $(BUILD_DIR)/bootloader/
	rm -f $(BUILD_DIR)/boot.efi
