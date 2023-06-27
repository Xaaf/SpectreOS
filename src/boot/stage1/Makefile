BUILD_DIR?=build/
ASM?=nasm

.PHONY: all stage1 clean

all: stage1

stage1: $(BUILD_DIR)/boot.bin

#
#	Build boot.bin
#
$(BUILD_DIR)/boot.bin:
	$(ASM) boot.asm -f bin -o $(BUILD_DIR)/stage1.bin

#
#	Clean
#
clean:
	rm -f $(BUILD_DIR)/stage1.bin