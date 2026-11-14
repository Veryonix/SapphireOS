; COM1, 38400 8N1. Used to report boot before the VGA console is up.
COM1 equ 0x3F8

serial_ready_msg db "SapphireOS ready", 13, 10, 0

serial_init:
    push eax
    push edx
    mov dx, COM1 + 1
    xor al, al
    out dx, al
    mov dx, COM1 + 3
    mov al, 0x80
    out dx, al
    mov dx, COM1 + 0
    mov al, 0x03
    out dx, al
    mov dx, COM1 + 1
    xor al, al
    out dx, al
    mov dx, COM1 + 3
    mov al, 0x03
    out dx, al
    mov dx, COM1 + 2
    mov al, 0xC7
    out dx, al
    mov dx, COM1 + 4
    mov al, 0x0B
    out dx, al
    pop edx
    pop eax
    ret

; AL = character.
serial_putc:
    push ebx
    push ecx
    push edx
    mov bl, al
    mov dx, COM1 + 5
    mov ecx, 100000
.wait:
    in al, dx
    test al, 0x20
    jnz .send
    dec ecx
    jnz .wait
.send:
    mov dx, COM1
    mov al, bl
    out dx, al
    pop edx
    pop ecx
    pop ebx
    ret

; ESI = NUL-terminated string.
serial_puts:
    push eax
    push esi
.next:
    mov al, [esi]
    test al, al
    jz .done
    call serial_putc
    inc esi
    jmp .next
.done:
    pop esi
    pop eax
    ret
