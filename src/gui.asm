; 800x600 desktop: sapphire background, top bar, draggable windows, terminal.

TOP_H equ 32
BORDER equ 2
TITLE_H equ 24
PAD equ 4
FONT equ 8
TERM_COLS equ 48
TERM_ROWS equ 20
WIN_COUNT equ 2

TERM_W equ BORDER * 2 + PAD * 2 + TERM_COLS * FONT
TERM_H equ BORDER * 2 + TITLE_H + PAD * 2 + TERM_ROWS * FONT

%macro FILL 5
    push dword %5
    push dword %4
    push dword %3
    push dword %2
    push dword %1
    call fill_rect
    add esp, 20
%endmacro

%macro COLOR 4
    mov al, %2
    mov ah, %3
    mov bl, %4
    call pack_rgb
    mov [%1], eax
%endmacro

vbe_ok db 0
vbe_mode dw 0
align 4
fb_ptr dd 0
fb_pitch dd 0
fb_rpos db 0
fb_gpos db 0
fb_bpos db 0

dirty db 0
mouse_left db 0
dragging db 0
align 4
drag_id dd 0
drag_dx dd 0
drag_dy dd 0
hit_id dd 0
win_draw_id dd 0
origin_x dd 0
origin_y dd 0
term_fg dd 0
cell_col dd 0
cell_row dd 0

col_desktop dd 0
col_topbar dd 0
col_title dd 0
col_title_dim dd 0
col_win dd 0
col_border dd 0
col_white dd 0
col_black dd 0
col_ink dd 0
vga_pal times 16 dd 0

win_x dd 24, 448
win_y dd 52, 84
win_w dd TERM_W, 260
win_h dd TERM_H, 160
win_title dd title_term, title_about
win_kind db 0, 1
win_z db 1, 0

title_term db "Terminal", 0
title_about db "About", 0
bar_title db "SapphireOS", 0
about_l1 db "SapphireOS v0.1", 0
about_l2 db "800x600, 32-bit", 0
about_l3 db "Drag a title bar.", 0
about_l4 db "Click to raise.", 0
desktop_up_msg db "desktop up", 13, 10, 0

term_buf times TERM_COLS * TERM_ROWS db ' '
term_col dd 0
term_row dd 0

vga_rgb:
    db 0, 0, 0
    db 0, 0, 170
    db 0, 170, 0
    db 0, 170, 170
    db 170, 0, 0
    db 170, 0, 170
    db 170, 85, 0
    db 170, 170, 170
    db 85, 85, 85
    db 85, 85, 255
    db 85, 255, 85
    db 85, 255, 255
    db 255, 85, 85
    db 255, 85, 255
    db 255, 255, 85
    db 255, 255, 255

cursor_glyph:
    dw 0x8000, 0xC000, 0xE000, 0xF000
    dw 0xF800, 0xFC00, 0xFE00, 0xFF00
    dw 0xFF80, 0xF800, 0xDC00, 0x8E00
    dw 0x0700, 0x0300, 0x0000, 0x0000

desktop_main:
    call gui_init_colors
    call mouse_init
    call shell_init
    call desktop_redraw
    mov esi, desktop_up_msg
    call serial_puts
.loop:
    cli
    call kbuf_pop
    jc .nokey
    sti
    call shell_on_char
    jmp .check
.nokey:
    sti
.check:
    call desktop_handle_mouse
    cmp byte [dirty], 0
    je .wait
    call desktop_redraw
    jmp .loop
.wait:
    cli
    cmp byte [dirty], 0
    jne .loop
    mov eax, [k_head]
    cmp eax, [k_tail]
    jne .loop
    sti
    hlt
    jmp .loop

desktop_handle_mouse:
    pushad
    mov al, [mouse_btn]
    and al, 1
    cmp al, [mouse_left]
    je .drag
    mov [mouse_left], al
    test al, al
    jz .release
    call hit_test
    cmp eax, 0
    jl .drag
    mov [hit_id], eax
    call raise_window
    mov byte [dirty], 1
    mov eax, [hit_id]
    call title_hit
    jc .drag
    mov byte [dragging], 1
    mov eax, [hit_id]
    mov [drag_id], eax
    shl eax, 2
    mov ebx, [mouse_x]
    sub ebx, [win_x + eax]
    mov [drag_dx], ebx
    mov ebx, [mouse_y]
    sub ebx, [win_y + eax]
    mov [drag_dy], ebx
    jmp .drag
.release:
    mov byte [dragging], 0
.drag:
    cmp byte [dragging], 0
    je .out
    cmp byte [mouse_moved], 0
    je .out
    mov eax, [drag_id]
    mov ebx, eax
    shl ebx, 2
    mov eax, [mouse_x]
    sub eax, [drag_dx]
    mov [win_x + ebx], eax
    mov eax, [mouse_y]
    sub eax, [drag_dy]
    mov [win_y + ebx], eax
    call clamp_window
    mov byte [dirty], 1
.out:
    mov byte [mouse_moved], 0
    popad
    ret

; EAX = window id, or -1.
hit_test:
    push ebx
    push ecx
    push esi
    mov ecx, WIN_COUNT
.next:
    dec ecx
    js .miss
    movzx eax, byte [win_z + ecx]
    mov ebx, eax
    shl ebx, 2
    mov esi, [mouse_x]
    cmp esi, [win_x + ebx]
    jl .next
    mov esi, [win_x + ebx]
    add esi, [win_w + ebx]
    cmp [mouse_x], esi
    jge .next
    mov esi, [mouse_y]
    cmp esi, [win_y + ebx]
    jl .next
    mov esi, [win_y + ebx]
    add esi, [win_h + ebx]
    cmp [mouse_y], esi
    jge .next
    pop esi
    pop ecx
    pop ebx
    ret
.miss:
    mov eax, -1
    pop esi
    pop ecx
    pop ebx
    ret

; EAX = id. CF = 0 when the pointer is inside the title bar.
title_hit:
    push ebx
    push ecx
    push edx
    mov ebx, eax
    shl ebx, 2
    mov ecx, [mouse_x]
    cmp ecx, [win_x + ebx]
    jl .no
    mov edx, [win_x + ebx]
    add edx, [win_w + ebx]
    cmp ecx, edx
    jge .no
    mov ecx, [mouse_y]
    cmp ecx, [win_y + ebx]
    jl .no
    mov edx, [win_y + ebx]
    add edx, TITLE_H
    cmp ecx, edx
    jge .no
    pop edx
    pop ecx
    pop ebx
    clc
    ret
.no:
    pop edx
    pop ecx
    pop ebx
    stc
    ret

; EAX = id. Moves that window to the front.
raise_window:
    push eax
    push ebx
    push ecx
    xor ecx, ecx
.find:
    cmp ecx, WIN_COUNT
    jae .out
    movzx ebx, byte [win_z + ecx]
    cmp ebx, eax
    je .found
    inc ecx
    jmp .find
.found:
    cmp ecx, WIN_COUNT - 1
    jae .place
    mov bl, [win_z + ecx + 1]
    mov [win_z + ecx], bl
    inc ecx
    jmp .found
.place:
    mov [win_z + WIN_COUNT - 1], al
.out:
    pop ecx
    pop ebx
    pop eax
    ret

; EBX = window index times 4.
clamp_window:
    push eax
    push ecx
    mov eax, [win_x + ebx]
    cmp eax, 0
    jge .x_lo
    xor eax, eax
.x_lo:
    mov ecx, SCREEN_W
    sub ecx, [win_w + ebx]
    cmp eax, ecx
    jle .x_hi
    mov eax, ecx
.x_hi:
    mov [win_x + ebx], eax
    mov eax, [win_y + ebx]
    cmp eax, TOP_H
    jge .y_lo
    mov eax, TOP_H
.y_lo:
    mov ecx, SCREEN_H
    sub ecx, [win_h + ebx]
    cmp eax, ecx
    jle .y_hi
    mov eax, ecx
.y_hi:
    mov [win_y + ebx], eax
    pop ecx
    pop eax
    ret

desktop_redraw:
    pushad
    cmp dword [fb_ptr], 0
    je .out
    mov byte [dirty], 0
    FILL 0, 0, SCREEN_W, SCREEN_H, [col_desktop]
    FILL 0, 0, SCREEN_W, TOP_H, [col_topbar]
    mov eax, 16
    mov ebx, 12
    mov esi, bar_title
    mov edx, [col_white]
    mov ecx, -1
    call draw_string
    xor ecx, ecx
.wins:
    cmp ecx, WIN_COUNT
    jae .cursor
    movzx eax, byte [win_z + ecx]
    push ecx
    call draw_window
    pop ecx
    inc ecx
    jmp .wins
.cursor:
    call draw_cursor
.out:
    popad
    ret

; EAX = window id.
draw_window:
    pushad
    mov [win_draw_id], eax
    mov ebx, eax
    shl ebx, 2
    FILL [win_x + ebx], [win_y + ebx], [win_w + ebx], [win_h + ebx], [col_border]

    mov eax, [win_x + ebx]
    add eax, BORDER
    mov ecx, [win_y + ebx]
    add ecx, TITLE_H
    mov edx, [win_w + ebx]
    sub edx, BORDER * 2
    mov esi, [win_h + ebx]
    sub esi, TITLE_H + BORDER
    FILL eax, ecx, edx, esi, [col_win]

    mov eax, [win_draw_id]
    cmp al, [win_z + WIN_COUNT - 1]
    jne .dim
    mov edi, [col_title]
    jmp .bar
.dim:
    mov edi, [col_title_dim]
.bar:
    mov eax, [win_x + ebx]
    add eax, BORDER
    mov ecx, [win_y + ebx]
    add ecx, BORDER
    mov edx, [win_w + ebx]
    sub edx, BORDER * 2
    mov esi, TITLE_H - BORDER
    FILL eax, ecx, edx, esi, edi

    mov eax, [win_draw_id]
    cmp byte [win_kind + eax], 0
    jne .about
    call draw_terminal
    jmp .caption
.about:
    call draw_about
.caption:
    mov ebx, [win_draw_id]
    shl ebx, 2
    mov esi, [win_title + ebx]
    mov eax, [win_x + ebx]
    add eax, 10
    mov ecx, [win_y + ebx]
    add ecx, 8
    mov ebx, ecx
    mov edx, [col_white]
    mov ecx, -1
    call draw_string
    popad
    ret

draw_terminal:
    pushad
    mov eax, [win_draw_id]
    shl eax, 2
    mov ebx, [win_x + eax]
    add ebx, BORDER + PAD
    mov [origin_x], ebx
    mov ebx, [win_y + eax]
    add ebx, TITLE_H + PAD
    mov [origin_y], ebx

    movzx eax, byte [vga_attr]
    mov ebx, eax
    shr ebx, 4
    and ebx, 0x0F
    mov edx, [vga_pal + ebx * 4]
    FILL [origin_x], [origin_y], TERM_COLS * FONT, TERM_ROWS * FONT, edx

    movzx eax, byte [vga_attr]
    and eax, 0x0F
    mov eax, [vga_pal + eax * 4]
    mov [term_fg], eax

    xor ecx, ecx
.row:
    cmp ecx, TERM_ROWS
    jge .done
    xor ebx, ebx
.col:
    cmp ebx, TERM_COLS
    jge .next_row
    mov eax, ecx
    imul eax, TERM_COLS
    add eax, ebx
    movzx eax, byte [term_buf + eax]
    cmp al, ' '
    je .next_col
    mov [cell_col], ebx
    mov [cell_row], ecx
    movzx edi, al
    mov eax, ebx
    shl eax, 3
    add eax, [origin_x]
    mov edx, ecx
    shl edx, 3
    add edx, [origin_y]
    mov ebx, edx
    push dword -1
    push dword [term_fg]
    push edi
    push ebx
    push eax
    call draw_char
    add esp, 20
    mov ebx, [cell_col]
    mov ecx, [cell_row]
.next_col:
    inc ebx
    jmp .col
.next_row:
    inc ecx
    jmp .row
.done:
    popad
    ret

draw_about:
    pushad
    mov eax, [win_x + 4]
    add eax, BORDER + PAD
    mov ebx, [win_y + 4]
    add ebx, TITLE_H + PAD
    mov edx, [col_ink]
    mov ecx, -1
    mov esi, about_l1
    call draw_string
    add ebx, 14
    mov esi, about_l2
    call draw_string
    add ebx, 16
    mov esi, about_l3
    call draw_string
    add ebx, 12
    mov esi, about_l4
    call draw_string
    popad
    ret

draw_cursor:
    pushad
    mov eax, [mouse_x]
    inc eax
    mov ebx, [mouse_y]
    inc ebx
    mov edx, [col_black]
    call draw_cursor_at
    mov eax, [mouse_x]
    mov ebx, [mouse_y]
    mov edx, [col_white]
    call draw_cursor_at
    popad
    ret

; EAX = x, EBX = y, EDX = color.
draw_cursor_at:
    pushad
    mov esi, cursor_glyph
    xor ecx, ecx
.row:
    cmp ecx, 16
    jge .done
    mov di, [esi]
    add esi, 2
    xor ebp, ebp
.col:
    cmp ebp, 16
    jge .next
    test di, 0x8000
    jz .skip
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    add eax, ebp
    add ebx, ecx
    call put_pixel
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
.skip:
    shl di, 1
    inc ebp
    jmp .col
.next:
    inc ecx
    jmp .row
.done:
    popad
    ret

; EAX = x, EBX = y, ESI = string, EDX = foreground, ECX = background (-1 skips it).
draw_string:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
.next:
    movzx edi, byte [esi]
    test edi, edi
    jz .done
    push ecx
    push edx
    push edi
    push ebx
    push eax
    call draw_char
    add esp, 20
    add eax, FONT
    inc esi
    jmp .next
.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Stack: x, y, character, foreground, background.
draw_char:
    pushad
    mov ebp, esp
    movzx esi, byte [ebp + 44]
    cmp esi, 127
    jbe .glyph
    mov esi, ' '
.glyph:
    shl esi, 3
    add esi, font8x8
    xor ecx, ecx
.row:
    cmp ecx, 8
    jge .done
    mov bl, [esi]
    inc esi
    xor edx, edx
.col:
    cmp edx, 8
    jge .next_row
    test bl, 0x80
    jnz .fg
    cmp dword [ebp + 52], -1
    je .advance
    push ebx
    push ecx
    push edx
    mov eax, [ebp + 36]
    add eax, edx
    mov ebx, [ebp + 40]
    add ebx, ecx
    mov edx, [ebp + 52]
    call put_pixel
    pop edx
    pop ecx
    pop ebx
    jmp .advance
.fg:
    push ebx
    push ecx
    push edx
    mov eax, [ebp + 36]
    add eax, edx
    mov ebx, [ebp + 40]
    add ebx, ecx
    mov edx, [ebp + 48]
    call put_pixel
    pop edx
    pop ecx
    pop ebx
.advance:
    shl bl, 1
    inc edx
    jmp .col
.next_row:
    inc ecx
    jmp .row
.done:
    popad
    ret

; EAX = x, EBX = y, EDX = color. Clips to the screen.
put_pixel:
    push eax
    push ebx
    push ecx
    push edx
    push edi
    cmp eax, 0
    jl .no
    cmp ebx, 0
    jl .no
    cmp eax, SCREEN_W
    jge .no
    cmp ebx, SCREEN_H
    jge .no
    mov edi, ebx
    imul edi, [fb_pitch]
    mov ecx, eax
    shl ecx, 2
    add edi, ecx
    add edi, [fb_ptr]
    mov [edi], edx
.no:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Stack: x, y, width, height, color.
fill_rect:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    cld
    mov eax, [ebp + 8]
    mov ebx, [ebp + 12]
    mov ecx, [ebp + 16]
    mov edx, [ebp + 20]
    cmp ecx, 0
    jle .out
    cmp edx, 0
    jle .out
    cmp eax, SCREEN_W
    jge .out
    cmp ebx, SCREEN_H
    jge .out
    cmp eax, 0
    jge .x_ok
    add ecx, eax
    xor eax, eax
    cmp ecx, 0
    jle .out
.x_ok:
    cmp ebx, 0
    jge .y_ok
    add edx, ebx
    xor ebx, ebx
    cmp edx, 0
    jle .out
.y_ok:
    mov esi, eax
    add esi, ecx
    cmp esi, SCREEN_W
    jle .w_ok
    mov ecx, SCREEN_W
    sub ecx, eax
.w_ok:
    mov esi, ebx
    add esi, edx
    cmp esi, SCREEN_H
    jle .h_ok
    mov edx, SCREEN_H
    sub edx, ebx
.h_ok:
    mov edi, [fb_pitch]
    imul edi, ebx
    mov esi, eax
    shl esi, 2
    add edi, esi
    add edi, [fb_ptr]
    mov eax, [ebp + 24]
    mov esi, [fb_pitch]
    mov ebx, ecx
    shl ebx, 2
    sub esi, ebx
.row:
    push ecx
    rep stosd
    pop ecx
    add edi, esi
    dec edx
    jnz .row
.out:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret

gui_init_colors:
    push eax
    push ebx
    push ecx
    push esi
    push edi
    COLOR col_desktop, 14, 61, 112
    COLOR col_topbar, 8, 28, 52
    COLOR col_title, 18, 72, 138
    COLOR col_title_dim, 78, 96, 118
    COLOR col_win, 232, 236, 242
    COLOR col_border, 12, 24, 40
    COLOR col_white, 255, 255, 255
    COLOR col_black, 0, 0, 0
    COLOR col_ink, 16, 32, 56
    mov esi, vga_rgb
    mov edi, vga_pal
    mov ecx, 16
.pal:
    mov al, [esi]
    mov ah, [esi + 1]
    mov bl, [esi + 2]
    add esi, 3
    push ecx
    push esi
    push edi
    call pack_rgb
    pop edi
    pop esi
    pop ecx
    mov [edi], eax
    add edi, 4
    loop .pal
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret

; AL = red, AH = green, BL = blue. EAX = packed pixel.
pack_rgb:
    push ebx
    push ecx
    push ebp
    movzx ebp, bl
    movzx ebx, al
    mov al, ah
    movzx eax, al
    mov cl, [fb_rpos]
    shl ebx, cl
    mov cl, [fb_gpos]
    shl eax, cl
    or ebx, eax
    mov eax, ebp
    mov cl, [fb_bpos]
    shl eax, cl
    or eax, ebx
    pop ebp
    pop ecx
    pop ebx
    ret

con_clear:
    cmp byte [vbe_ok], 0
    jne term_clear
    jmp vga_clear

con_putc:
    cmp byte [vbe_ok], 0
    jne term_putc
    jmp vga_putc

con_puts:
    push eax
    push esi
.next:
    mov al, [esi]
    test al, al
    jz .done
    call con_putc
    inc esi
    jmp .next
.done:
    pop esi
    pop eax
    ret

con_newline:
    push eax
    mov al, 10
    call con_putc
    pop eax
    ret

con_backspace:
    cmp byte [vbe_ok], 0
    jne term_backspace
    jmp vga_backspace

con_recolor:
    cmp byte [vbe_ok], 0
    jne term_recolor
    jmp vga_recolor

con_put_hex8:
    push eax
    push ebx
    mov bl, al
    shr al, 4
    call hex_digit
    call con_putc
    mov al, bl
    and al, 0x0F
    call hex_digit
    call con_putc
    pop ebx
    pop eax
    ret

term_clear:
    push eax
    push ecx
    push edi
    mov edi, term_buf
    mov ecx, TERM_COLS * TERM_ROWS
    mov al, ' '
    cld
    rep stosb
    mov dword [term_col], 0
    mov dword [term_row], 0
    mov byte [dirty], 1
    pop edi
    pop ecx
    pop eax
    ret

term_putc:
    push eax
    push ebx
    cmp al, 13
    je .out
    cmp al, 10
    je .nl
    mov ebx, [term_row]
    imul ebx, TERM_COLS
    add ebx, [term_col]
    mov [term_buf + ebx], al
    inc dword [term_col]
    cmp dword [term_col], TERM_COLS
    jb .mark
.nl:
    mov dword [term_col], 0
    inc dword [term_row]
    cmp dword [term_row], TERM_ROWS
    jb .mark
    call term_scroll
    mov dword [term_row], TERM_ROWS - 1
.mark:
    mov byte [dirty], 1
.out:
    pop ebx
    pop eax
    ret

term_backspace:
    push ebx
    cmp dword [term_col], 0
    jne .left
    cmp dword [term_row], 0
    je .out
    dec dword [term_row]
    mov dword [term_col], TERM_COLS - 1
    jmp .wipe
.left:
    dec dword [term_col]
.wipe:
    mov ebx, [term_row]
    imul ebx, TERM_COLS
    add ebx, [term_col]
    mov byte [term_buf + ebx], ' '
    mov byte [dirty], 1
.out:
    pop ebx
    ret

term_recolor:
    mov byte [dirty], 1
    ret

term_scroll:
    push eax
    push ecx
    push esi
    push edi
    mov esi, term_buf + TERM_COLS
    mov edi, term_buf
    mov ecx, TERM_COLS * (TERM_ROWS - 1)
    cld
    rep movsb
    mov ecx, TERM_COLS
    mov al, ' '
    rep stosb
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
