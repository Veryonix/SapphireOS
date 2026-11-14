; SapphireOS kernel. Entered in real mode at 0x1000 by the boot sector.
[org 0x1000]

%ifndef KERNEL_SECTORS
%define KERNEL_SECTORS 32
%endif

[bits 16]
kernel_entry:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    mov ax, 0x0003
    int 0x10
    cli

    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG:pm_start

[bits 32]
pm_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    mov ebp, esp
    cld

    call serial_init
    mov esi, serial_ready_msg
    call serial_puts

    call pic_remap
    call idt_init
    call shell_main

.halt:
    cli
    hlt
    jmp .halt

%include "gdt.asm"
%include "serial.asm"
%include "vga.asm"
%include "irq.asm"
%include "keyboard.asm"
%include "shell.asm"

kernel_end:
%if (kernel_end - $$) > (KERNEL_SECTORS * 512)
%error kernel exceeds KERNEL_SECTORS
%endif
