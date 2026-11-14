; PS/2 auxiliary device. IRQ12 delivers three-byte movement packets.

mouse_cycle db 0
mouse_pkt db 0, 0, 0
mouse_x dd 400
mouse_y dd 300
mouse_btn db 0
mouse_moved db 0

mouse_init:
    push eax
    push ebx
    push ecx
    push edx

    mov al, 0xAD
    call kbc_cmd
    mov al, 0xA7
    call kbc_cmd

    mov ecx, 32
.flush:
    in al, 0x64
    test al, 1
    jz .flushed
    in al, 0x60
    loop .flush
.flushed:
    mov al, 0xA8
    call kbc_cmd

    mov al, 0x20
    call kbc_cmd
    call kbc_wait_read
    jc .kb_on
    in al, 0x60
    or al, 0x03
    and al, 0xCF
    mov bl, al

    mov al, 0x60
    call kbc_cmd
    call kbc_wait_write
    mov al, bl
    out 0x60, al

    mov al, 0xF6
    call mouse_write
    mov al, 0xF4
    call mouse_write

.kb_on:
    mov al, 0xAE
    call kbc_cmd
    mov byte [mouse_cycle], 0
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; AL = command byte for the auxiliary device.
mouse_write:
    push ebx
    mov bl, al
    call kbc_wait_write
    mov al, 0xD4
    out 0x64, al
    call kbc_wait_write
    mov al, bl
    out 0x60, al
    call kbc_wait_read
    jc .timeout
    in al, 0x60
.timeout:
    pop ebx
    ret

; AL = 8042 command.
kbc_cmd:
    push eax
    call kbc_wait_write
    pop eax
    out 0x64, al
    ret

kbc_wait_write:
    push eax
    push ecx
    mov ecx, 100000
.wait:
    in al, 0x64
    test al, 2
    jz .ready
    dec ecx
    jnz .wait
.ready:
    pop ecx
    pop eax
    ret

; CF = 1 on timeout.
kbc_wait_read:
    push ecx
    mov ecx, 100000
.wait:
    in al, 0x64
    test al, 1
    jnz .ready
    dec ecx
    jnz .wait
    pop ecx
    stc
    ret
.ready:
    pop ecx
    clc
    ret

; Called from the IRQ12 ISR. Data segment is already loaded.
mouse_handle:
    push eax
    push ebx
    push edx
    mov dx, 0x64
    in al, dx
    test al, 1
    jz .done
    test al, 0x20
    jz .done
    mov dx, 0x60
    in al, dx

    movzx ebx, byte [mouse_cycle]
    test ebx, ebx
    jnz .store
    test al, 0x08
    jz .done
.store:
    mov [mouse_pkt + ebx], al
    inc ebx
    cmp ebx, 3
    jb .save
    xor ebx, ebx
    call mouse_apply
.save:
    mov [mouse_cycle], bl
.done:
    pop edx
    pop ebx
    pop eax
    ret

mouse_apply:
    push eax
    push ebx
    push edx
    mov bl, [mouse_pkt]
    test bl, 0xC0
    jnz .buttons

    movsx eax, byte [mouse_pkt + 1]
    add eax, [mouse_x]
    cmp eax, 0
    jge .x_lo
    xor eax, eax
.x_lo:
    cmp eax, SCREEN_W - 1
    jle .x_hi
    mov eax, SCREEN_W - 1
.x_hi:
    mov [mouse_x], eax

    movsx eax, byte [mouse_pkt + 2]
    mov edx, [mouse_y]
    sub edx, eax
    cmp edx, 0
    jge .y_lo
    xor edx, edx
.y_lo:
    cmp edx, SCREEN_H - 1
    jle .y_hi
    mov edx, SCREEN_H - 1
.y_hi:
    mov [mouse_y], edx
    mov byte [mouse_moved], 1
    mov byte [cursor_dirty], 1

.buttons:
    and bl, 7
    mov [mouse_btn], bl
    mov byte [cursor_dirty], 1
    pop edx
    pop ebx
    pop eax
    ret
