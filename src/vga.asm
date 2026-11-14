; VGA text mode, 80x25 at 0xB8000.
VGA_MEM equ 0xB8000
VGA_COLS equ 80
VGA_ROWS equ 25

vga_attr db 0x1F
cursor_row dd 0
cursor_col dd 0

vga_clear:
    push eax
    push ecx
    push edi
    mov edi, VGA_MEM
    mov ecx, VGA_COLS * VGA_ROWS
    mov ah, [vga_attr]
    mov al, ' '
    rep stosw
    mov dword [cursor_row], 0
    mov dword [cursor_col], 0
    call vga_update_cursor
    pop edi
    pop ecx
    pop eax
    ret

; AL = character. CR is ignored, LF scrolls as needed.
vga_putc:
    push eax
    push ebx
    push edi
    cmp al, 13
    je .done
    cmp al, 10
    je .nl
    mov ah, [vga_attr]
    mov ebx, [cursor_row]
    imul ebx, VGA_COLS
    add ebx, [cursor_col]
    shl ebx, 1
    mov edi, VGA_MEM
    mov [edi + ebx], ax
    inc dword [cursor_col]
    cmp dword [cursor_col], VGA_COLS
    jb .upd
.nl:
    mov dword [cursor_col], 0
    inc dword [cursor_row]
    cmp dword [cursor_row], VGA_ROWS
    jb .upd
    call vga_scroll
    mov dword [cursor_row], VGA_ROWS - 1
.upd:
    call vga_update_cursor
.done:
    pop edi
    pop ebx
    pop eax
    ret

vga_newline:
    push eax
    mov al, 10
    call vga_putc
    pop eax
    ret

; ESI = NUL-terminated string.
vga_puts:
    push eax
    push esi
.next:
    mov al, [esi]
    test al, al
    jz .done
    call vga_putc
    inc esi
    jmp .next
.done:
    pop esi
    pop eax
    ret

vga_backspace:
    push eax
    push ebx
    push edi
    cmp dword [cursor_col], 0
    jne .left
    cmp dword [cursor_row], 0
    je .done
    dec dword [cursor_row]
    mov dword [cursor_col], VGA_COLS - 1
    jmp .wipe
.left:
    dec dword [cursor_col]
.wipe:
    mov ah, [vga_attr]
    mov al, ' '
    mov ebx, [cursor_row]
    imul ebx, VGA_COLS
    add ebx, [cursor_col]
    shl ebx, 1
    mov edi, VGA_MEM
    mov [edi + ebx], ax
    call vga_update_cursor
.done:
    pop edi
    pop ebx
    pop eax
    ret

vga_recolor:
    push eax
    push ecx
    push edi
    mov edi, VGA_MEM + 1
    mov ecx, VGA_COLS * VGA_ROWS
    mov al, [vga_attr]
.next:
    mov [edi], al
    add edi, 2
    loop .next
    pop edi
    pop ecx
    pop eax
    ret

vga_scroll:
    push eax
    push ecx
    push esi
    push edi
    mov esi, VGA_MEM + (VGA_COLS * 2)
    mov edi, VGA_MEM
    mov ecx, VGA_COLS * (VGA_ROWS - 1)
    rep movsw
    mov ah, [vga_attr]
    mov al, ' '
    mov ecx, VGA_COLS
    rep stosw
    pop edi
    pop esi
    pop ecx
    pop eax
    ret

vga_update_cursor:
    push eax
    push ebx
    push edx
    mov eax, [cursor_row]
    imul eax, VGA_COLS
    add eax, [cursor_col]
    mov ebx, eax
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al
    mov dx, 0x3D5
    mov al, bl
    out dx, al
    mov dx, 0x3D4
    mov al, 0x0E
    out dx, al
    mov dx, 0x3D5
    mov al, bh
    out dx, al
    pop edx
    pop ebx
    pop eax
    ret

; AL = value, prints two uppercase hex digits.
vga_put_hex8:
    push eax
    push ebx
    mov bl, al
    shr al, 4
    call hex_digit
    call vga_putc
    mov al, bl
    and al, 0x0F
    call hex_digit
    call vga_putc
    pop ebx
    pop eax
    ret

hex_digit:
    cmp al, 10
    jb .dec
    add al, 'A' - 10
    ret
.dec:
    add al, '0'
    ret
