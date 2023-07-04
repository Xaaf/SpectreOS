# mkdir if build/ doesn't exist
mkdir -p build

#
#   Compile
# For Makefile, CFLAGS are -ffreestanding -Ihome/xaaf/Prereqs/gnu-efi/inc -Ihome/xaaf/Prereqs/gnu-efi/inc/x86_64 -Ihome/xaaf/Prereqs/gnu-efi/inc/protocol -c
#
x86_64-w64-mingw32-gcc -ffreestanding -I/home/xaaf/Prereqs/gnu-efi/inc -I/home/xaaf/Prereqs/gnu-efi/inc/x86_64 -I/home/xaaf/Prereqs/gnu-efi/inc/protocol -c -o build/main.o src/main.c
x86_64-w64-mingw32-gcc -ffreestanding -I/home/xaaf/Prereqs/gnu-efi/inc -I/home/xaaf/Prereqs/gnu-efi/inc/x86_64 -I/home/xaaf/Prereqs/gnu-efi/inc/protocol -c -o build/data.o gnu-efi/lib/data.c

#
#   Link
# For Makefile, LDFLAGS are -nostdlib -Wl,-dll -shared -Wl,--subsystem,10 -e efi_main
#
x86_64-w64-mingw32-gcc -nostdlib -Wl,-dll -shared -Wl,--subsystem,10 -e efi_main -o build/BOOTx64.EFI build/main.o build/data.o

#
#   Creat FAT image
#
dd if=/dev/zero of=build/Spectre.img bs=1k count=1440
mformat -i build/Spectre.img -f 1440 ::
mmd -i build/Spectre.img ::/EFI
mmd -i build/Spectre.img ::/EFI/BOOT
mcopy -i build/Spectre.img build/BOOTx64.EFI ::/EFI/BOOT

#
#   Create ISO disk image
#
mkdir -p build/iso
cp build/Spectre.img build/iso/
xorriso -as mkisofs -R -f -e Spectre.img -no-emul-boot -o build/Spectre.iso build/iso
