NASM ?= nasm
QEMU ?= qemu-system-i386

BUILD := build
IMAGE := $(BUILD)/sapphireos.img
BOOT := $(BUILD)/boot.bin
KERNEL := $(BUILD)/kernel.bin
KERNEL_SECTORS := 48

KERNEL_SRCS := src/kernel.asm src/gdt.asm src/serial.asm src/vga.asm src/irq.asm src/keyboard.asm src/shell.asm src/vbe.asm src/mouse.asm src/font.asm src/gui.asm

.PHONY: all run clean

all: $(IMAGE)

$(BUILD):
	mkdir -p $(BUILD)

$(BOOT): src/boot.asm | $(BUILD)
	$(NASM) -f bin -DKERNEL_SECTORS=$(KERNEL_SECTORS) $< -o $@

$(KERNEL): $(KERNEL_SRCS) | $(BUILD)
	$(NASM) -f bin -DKERNEL_SECTORS=$(KERNEL_SECTORS) -I src/ src/kernel.asm -o $@

$(IMAGE): $(BOOT) $(KERNEL)
	@test $$(stat -c%s $(BOOT)) -eq 512
	@test $$(stat -c%s $(KERNEL)) -le $$(($(KERNEL_SECTORS) * 512))
	dd if=/dev/zero of=$@ bs=512 count=$$(($(KERNEL_SECTORS) + 1)) status=none
	dd if=$(BOOT) of=$@ conv=notrunc bs=512 status=none
	dd if=$(KERNEL) of=$@ conv=notrunc bs=512 seek=1 status=none

run: all
	$(QEMU) -drive format=raw,file=$(IMAGE) -vga std -serial stdio -display gtk,zoom-to-fit=off,grab-on-hover=off

clean:
	rm -rf $(BUILD)
