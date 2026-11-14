; Real-mode VBE setup. Selects 800x600 with 32 bits per pixel and a linear
; framebuffer. On failure the caller stays in VGA text mode.
; Requires DS = 0 and a stack. Interrupts must be enabled for the BIOS.

enable_a20:
    in al, 0x92
    or al, 2
    and al, 0xFE
    out 0x92, al
    ret

vbe_setup:
    pusha
    xor ax, ax
    mov ds, ax
    mov byte [vbe_ok], 0
    mov word [vbe_mode], 0

    mov ax, 0x7000
    mov es, ax
    xor di, di
    mov cx, 512
    xor ax, ax
    cld
    rep stosw

    mov ax, 0x7000
    mov es, ax
    xor di, di
    mov dword [es:di], 'VBE2'
    mov ax, 0x4F00
    int 0x10
    cld
    cmp ax, 0x004F
    jne .fail

    xor ax, ax
    mov ds, ax
    mov ax, 0x7000
    mov es, ax
    mov ax, [es:0x0E]
    mov [mode_list_off], ax
    mov ax, [es:0x10]
    mov [mode_list_seg], ax

    mov cx, 0x143
    call vbe_try_mode
    jnc .ok

    mov si, [mode_list_off]
    mov ax, [mode_list_seg]
    mov fs, ax
    mov bx, 128
.search:
    mov cx, [fs:si]
    cmp cx, 0xFFFF
    je .fail
    add si, 2
    dec bx
    jz .fail
    mov [mode_list_off], si
    mov [mode_scan_left], bx
    call vbe_try_mode
    pushf
    xor ax, ax
    mov ds, ax
    mov si, [mode_list_off]
    mov ax, [mode_list_seg]
    mov fs, ax
    mov bx, [mode_scan_left]
    popf
    jc .search

.ok:
    mov byte [vbe_ok], 1
    jmp .done

.fail:
    xor ax, ax
    mov ds, ax
    mov ax, 0x0003
    int 0x10
    xor ax, ax
    mov ds, ax
    mov byte [vbe_ok], 0

.done:
    popa
    ret

; CX = VBE mode. CF = 0 when an 800x600x32 linear mode was set.
vbe_try_mode:
    push cx
    mov ax, 0x7000
    mov es, ax
    mov di, 0x200
    mov ax, 0x4F01
    int 0x10
    cld
    cmp ax, 0x004F
    jne .no

    xor ax, ax
    mov ds, ax
    mov ax, 0x7000
    mov es, ax
    mov ax, [es:0x200]
    test ax, 0x0080
    jz .no
    test ax, 0x0010
    jz .no
    cmp word [es:0x212], 800
    jne .no
    cmp word [es:0x214], 600
    jne .no
    cmp byte [es:0x219], 32
    jne .no
    mov eax, [es:0x228]
    test eax, eax
    jz .no
    mov [fb_ptr], eax
    movzx eax, word [es:0x210]
    test eax, eax
    jz .no
    mov [fb_pitch], eax
    mov al, [es:0x220]
    mov [fb_rpos], al
    mov al, [es:0x222]
    mov [fb_gpos], al
    mov al, [es:0x224]
    mov [fb_bpos], al

    pop cx
    push cx
    mov [vbe_mode], cx
    mov bx, cx
    or bx, 0x4000
    mov ax, 0x4F02
    int 0x10
    cld
    cmp ax, 0x004F
    jne .no
    pop cx
    clc
    ret
.no:
    pop cx
    stc
    ret

mode_list_off dw 0
mode_list_seg dw 0
mode_scan_left dw 0
