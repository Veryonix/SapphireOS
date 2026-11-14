; PS/2 scancode set 1. IRQ1 feeds a ring buffer; the shell drains it.
KBUF_SIZE equ 128
KBUF_MASK equ 127

kbuf times KBUF_SIZE db 0
k_head dd 0
k_tail dd 0

shift_l db 0
shift_r db 0
caps db 0
ext_next db 0

; Called from the IRQ1 ISR with the data segment already loaded.
keyboard_handle:
    push eax
    push ebx
    push edx
    mov dx, 0x64
    in al, dx
    test al, 1
    jz .done
    test al, 0x20
    jnz .done
    mov dx, 0x60
    in al, dx
    call on_scancode
.done:
    pop edx
    pop ebx
    pop eax
    ret

; AL = scancode.
on_scancode:
    cmp al, 0xE0
    je .prefix
    cmp al, 0xE1
    je .prefix
    cmp byte [ext_next], 0
    je .normal
    mov byte [ext_next], 0
    ret
.prefix:
    mov byte [ext_next], 1
    ret
.normal:
    cmp al, 0x2A
    je .lson
    cmp al, 0x36
    je .rson
    cmp al, 0xAA
    je .lsoff
    cmp al, 0xB6
    je .rsoff
    cmp al, 0x3A
    je .toggle_caps
    test al, 0x80
    jnz .ret
    movzx ebx, al
    cmp ebx, 128
    jae .ret
    cmp byte [shift_l], 0
    jne .shifted
    cmp byte [shift_r], 0
    jne .shifted
    mov al, [keymap_plain + ebx]
    jmp .apply_caps
.shifted:
    mov al, [keymap_shift + ebx]
.apply_caps:
    cmp byte [caps], 0
    je .store
    cmp al, 'a'
    jb .upper
    cmp al, 'z'
    ja .store
    sub al, 32
    jmp .store
.upper:
    cmp al, 'A'
    jb .store
    cmp al, 'Z'
    ja .store
    add al, 32
.store:
    test al, al
    jz .ret
    call kbuf_push
.ret:
    ret
.lson:
    mov byte [shift_l], 1
    ret
.rson:
    mov byte [shift_r], 1
    ret
.lsoff:
    mov byte [shift_l], 0
    ret
.rsoff:
    mov byte [shift_r], 0
    ret
.toggle_caps:
    xor byte [caps], 1
    ret

; AL = byte. Drops the byte when the ring is full.
kbuf_push:
    push ebx
    push ecx
    mov ebx, [k_tail]
    mov ecx, ebx
    inc ecx
    and ecx, KBUF_MASK
    cmp ecx, [k_head]
    je .full
    mov [kbuf + ebx], al
    mov [k_tail], ecx
.full:
    pop ecx
    pop ebx
    ret

; OUT: AL = byte, CF = 1 when empty. Call with interrupts cleared.
kbuf_pop:
    push ebx
    mov eax, [k_head]
    cmp eax, [k_tail]
    je .empty
    mov bl, [kbuf + eax]
    inc eax
    and eax, KBUF_MASK
    mov [k_head], eax
    mov al, bl
    pop ebx
    clc
    ret
.empty:
    pop ebx
    stc
    ret

keymap_plain:
    db 0, 0
    db '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, 0
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 10, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', 0x27, 0x60, 0, 0x5C
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' '
    times 128 - ($ - keymap_plain) db 0

keymap_shift:
    db 0, 0
    db '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 8, 0
    db 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 10, 0
    db 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', 0x22, '~', 0, '|'
    db 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, '*', 0, ' '
    times 128 - ($ - keymap_shift) db 0
keymap_shift_end:

%if (keymap_shift - keymap_plain) != 128
%error plain keymap size
%endif
%if (keymap_shift_end - keymap_shift) != 128
%error shift keymap size
%endif
