; SapphireOS BIOS boot sector. Loads the kernel at 0x1000 and jumps to it.
[org 0x7C00]
[bits 16]

KERNEL_OFFSET equ 0x1000
%ifndef KERNEL_SECTORS
%define KERNEL_SECTORS 48
%endif

jmp 0x0000:start

start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    mov [boot_drive], dl
    sti

    mov si, msg_load
    call bios_print
    call load_kernel
    jc disk_fail
    jmp 0x0000:KERNEL_OFFSET

disk_fail:
    mov si, msg_err
    call bios_print
.hang:
    cli
    hlt
    jmp .hang

; CF set on failure.
load_kernel:
    mov ah, 0x41
    mov bx, 0x55AA
    mov dl, [boot_drive]
    int 0x13
    jc load_chs
    cmp bx, 0xAA55
    jne load_chs
    test cx, 1
    jz load_chs

    mov si, dap
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    jc load_chs
    clc
    ret

load_chs:
    mov word [spt], 63
    mov word [heads], 16
    mov ah, 0x08
    mov dl, [boot_drive]
    xor di, di
    mov es, di
    int 0x13
    jc .geom_done
    xor ah, ah
    mov al, cl
    and al, 0x3F
    jz .geom_done
    mov [spt], ax
    mov al, dh
    xor ah, ah
    inc ax
    mov [heads], ax
.geom_done:
    xor ax, ax
    mov es, ax
    mov ax, 1
    mov cx, KERNEL_SECTORS
    mov bx, KERNEL_OFFSET
.next:
    push ax
    push cx
    push bx
    call read_one
    jc .read_fail
    pop bx
    pop cx
    pop ax
    add bx, 512
    inc ax
    loop .next
    clc
    ret
.read_fail:
    pop bx
    pop cx
    pop ax
    stc
    ret

; AX = LBA, BX = destination offset, ES = 0. CF set on error.
read_one:
    push bp
    mov bp, sp
    push bx
    xor dx, dx
    div word [spt]
    mov cl, dl
    inc cl
    xor dx, dx
    div word [heads]
    mov dh, dl
    mov ch, al
    mov al, ah
    shl al, 6
    or cl, al
    mov dl, [boot_drive]
    mov bx, [bp - 2]
    mov ax, 0x0201
    int 0x13
    pop bx
    pop bp
    ret

bios_print:
    pusha
.next:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .next
.done:
    popa
    ret

boot_drive db 0
spt dw 63
heads dw 16
msg_load db "Loading SapphireOS...", 13, 10, 0
msg_err db "Disk error", 13, 10, 0

align 4, db 0
dap:
    db 0x10
    db 0
    dw KERNEL_SECTORS
    dw KERNEL_OFFSET
    dw 0
    dd 1
    dd 0

times 510 - ($ - $$) db 0
dw 0xAA55
