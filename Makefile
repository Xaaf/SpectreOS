# Name of the operating system
OSNAME = SpectreOS

SRCDIR = src
SRCDIR_KERNEL  := src/kernel
SRCDIR_BOOTLOADER  := src/bootloader
OBJDIR  := obj
BUILDDIR = bin
GNUEFI = src/3rdparty/gnu-efi

KERNEL = kernel
THIRDPARTY = 3rdparty

CC = gcc
CFLAGS = -ffreestanding -fshort-wchar -I$(GNUEFI)/inc -I$(GNUEFI)/inc/x86_64 -I$(GNUEFI)/inc/protocol

LD = ld
LDFLAGS = -nostdlib -znocombreloc -T $(GNUEFI)/gnuefi/elf_x86_64_efi.lds -shared -Bsymbolic

# All source files
SRCS_BOOTLOADERS := $(shell find $(SRCDIR_BOOTLOADER) -name "*.c")
OBJS_BOOTLOADER  = $(OBJDIR)/$(patsubst %.c,%.o,$(SRCS_BOOTLOADERS))

SOBJS = $(patsubst %.o,%.so,$(OBJS_BOOTLOADER))

OBJDIRS := $(shell dirname $(patsubst %, $(OBJDIR)/%, $(SRCDIR_BOOTLOADER)))

# NOTE: GCC CAN ONLY OUTPUT *ONE* .o FILE AT A TIME! THIS IS WHY
# 		WE HAVE TO HAVE A LOOP LIKE THIS!
$(OBJDIR)/%.o: $(SRCDIR_BOOTLOADER)/%.c
	@ echo ! ===== COMPILING $^
	@ mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $^ -o $@

bootloader: $(OBJS_BOOTLOADER) link

link:
	@ echo ! ===== LINKING
	$(LD) $(LDFLAGS) -o $(BUILDDIR)/kernel.elf $(OBJS_BOOTLOADER)

setup:
	@ mkdir $(OBJDIR)
	@ mkdir $(SRCDIR)
	@ mkdir $(BUILDDIR)

logdirs:
	@ echo ! SOURCES : $(SRCS_BOOTLOADERS)
	@ echo ! OBJECTS : $(OBJS_BOOTLOADER)
	@ echo ! SOBJECTS: $(SOBJS)
	@ echo ! OBJ DIRS: $(OBJDIRS)
	@ echo ! -I$(GNUEFI)/inc/x86_64