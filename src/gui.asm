; 800x600 desktop. Compact chrome, 8x16 text, resize, multi-terminal.

MENU_H equ 22
TOP_H equ MENU_H
BORDER equ 1
TITLE_H equ 22
PAD equ 4
FONT equ 8
FONT_H equ 16
TEXT_DY equ (TITLE_H - FONT_H) / 2
TERM_COLS equ 46
TERM_ROWS equ 10
TERM_COUNT equ 3
ABOUT_ID equ 3
WIN_COUNT equ 4
TERM_CELLS equ (TERM_COLS * TERM_ROWS)
LINE_STRIDE equ 70
DOCK_W equ 88
DOCK_H equ 34
DOCK_X equ (SCREEN_W - DOCK_W) / 2
DOCK_Y equ SCREEN_H - 8 - DOCK_H
ICON equ 24
ICON_GAP equ 10
ICON0_X equ DOCK_X + 12
ICON1_X equ ICON0_X + ICON + ICON_GAP
ICON_Y equ DOCK_Y + 4
CUR_S equ 16
BACK_BUFFER equ 0x100000
BTN_R equ 4
DROP_W equ 132
DROP_H equ 20
MENU_FILE_X equ 92
MENU_EDIT_X equ 132
MENU_VIEW_X equ 172
MENU_WIN_X equ 212
MENU_ITEM_W equ 36
MENU_WIN_W equ 52
CLOCK_X equ (SCREEN_W - 12 - 8 * FONT)
RESIZE_ZONE equ 12
MIN_WIN_W equ 160
MIN_WIN_H equ (TITLE_H + 48)

TERM_W equ BORDER * 2 + PAD * 2 + TERM_COLS * FONT
TERM_H equ BORDER * 2 + TITLE_H + PAD * 2 + TERM_ROWS * FONT_H

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
fb_front dd 0
fb_back dd 0
fb_target dd 0
fb_pitch dd 0
fb_rpos db 0
fb_gpos db 0
fb_bpos db 0

content_dirty db 0
cursor_dirty db 0
have_cursor db 0
mouse_left db 0
dragging db 0
resizing db 0
menu_open db 0
align 4
drag_id dd 0
drag_dx dd 0
drag_dy dd 0
resize_id dd 0
resize_ox dd 0
resize_oy dd 0
resize_ow dd 0
resize_oh dd 0
hit_id dd 0
win_draw_id dd 0
origin_x dd 0
origin_y dd 0
term_fg dd 0
cell_col dd 0
cell_row dd 0
btn_hit dd 0
active_term dd 0

col_desktop dd 0
col_topbar dd 0
col_title dd 0
col_title_dim dd 0
col_win dd 0
col_border dd 0
col_white dd 0
col_black dd 0
col_ink dd 0
col_menu dd 0
col_menu_dim dd 0
col_menu_hi dd 0
col_dock dd 0
col_shadow dd 0
col_line dd 0
col_red dd 0
col_yellow dd 0
col_green dd 0
col_icon_term dd 0
col_icon_about dd 0
timer_ticks dd 0
clock_stamp dd 0
cur_x dd 0
cur_y dd 0
cur_w dd 0
cur_h dd 0
disc_cx dd 0
disc_cy dd 0
disc_r dd 0
disc_col dd 0
cursor_bg times CUR_S * CUR_S dd 0
clock_str db "12:00 AM", 0
clock_prev db "12:00 AM", 0
vga_pal times 16 dd 0

win_x dd 16, 36, 56, 420
win_y dd 28, 48, 68, 48
win_w dd TERM_W, TERM_W, TERM_W, 200
win_h dd TERM_H, TERM_H, TERM_H, 148
win_sx dd 16, 36, 56, 420
win_sy dd 28, 48, 68, 48
win_sw dd TERM_W, TERM_W, TERM_W, 200
win_sh dd TERM_H, TERM_H, TERM_H, 148
win_title dd title_term, title_term, title_term, title_about
win_kind db 0, 0, 0, 1
win_z db 1, 2, 3, 0
win_vis db 1, 0, 0, 1
win_zoom db 0, 0, 0, 0

title_term db "Terminal", 0
title_about db "About", 0
bar_title db "SapphireOS", 0
menu_file db "File", 0
menu_edit db "Edit", 0
menu_view db "View", 0
menu_window db "Window", 0
item_new db "New Terminal", 0
item_close db "Close Window", 0
item_clear db "Clear", 0
item_copy db "Copy", 0
item_zoom db "Zoom", 0
item_show db "Show All", 0
about_l1 db "SapphireOS", 0
about_l2 db "A small desktop.", 0
about_l3 db "Drag a title bar.", 0
about_l4 db "Resize at a corner.", 0
about_l5 db "File opens terminals.", 0
desktop_up_msg db "desktop up", 13, 10, 0

term_bufs times TERM_COUNT * TERM_CELLS db ' '
term_col_arr times TERM_COUNT dd 0
term_row_arr times TERM_COUNT dd 0
term_lines times TERM_COUNT * LINE_STRIDE db 0
term_llens times TERM_COUNT dd 0

vga_rgb:
    db 28, 28, 30
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
    mov eax, [fb_ptr]
    mov [fb_front], eax
    mov dword [fb_back], BACK_BUFFER
    mov dword [fb_target], BACK_BUFFER
    mov byte [vga_attr], 0x0F
    call gui_init_colors
    call mouse_init
    mov dword [active_term], 0
    call shell_init
    call read_clock
    mov esi, clock_str
    mov edi, clock_prev
    mov ecx, 8
    cld
    rep movsb
    call desktop_redraw
    mov esi, desktop_up_msg
    call serial_puts
.loop:
    cli
    call kbuf_pop
    jc .nokey
    sti
    call focus_front_term
    call shell_on_char
    jmp .check
.nokey:
    sti
.check:
    call desktop_handle_mouse
    call clock_poll
    cmp byte [content_dirty], 0
    je .cursor
    call desktop_redraw
    jmp .loop
.cursor:
    cmp byte [cursor_dirty], 0
    je .wait
    call move_cursor
    mov byte [cursor_dirty], 0
    jmp .loop
.wait:
    cli
    cmp byte [content_dirty], 0
    jne .loop
    cmp byte [cursor_dirty], 0
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
    call hit_menubar
    cmp eax, 0
    je .not_bar
    cmp al, [menu_open]
    jne .open_menu
    mov byte [menu_open], 0
    jmp .menu_dirty
.open_menu:
    mov [menu_open], al
.menu_dirty:
    mov byte [content_dirty], 1
    jmp .drag
.not_bar:
    cmp byte [menu_open], 0
    je .no_menu
    call hit_dropdown
    cmp eax, 0
    jl .close_menu
    call menu_action
    mov byte [menu_open], 0
    mov byte [content_dirty], 1
    jmp .drag
.close_menu:
    mov byte [menu_open], 0
    mov byte [content_dirty], 1
.no_menu:
    call hit_dock
    cmp eax, 0
    jl .window
    mov [hit_id], eax
    mov byte [win_vis + eax], 1
    call raise_window
    cmp eax, TERM_COUNT
    jae .dock_dirty
    call set_active_term
.dock_dirty:
    mov byte [content_dirty], 1
    jmp .drag
.window:
    call hit_test
    cmp eax, 0
    jl .drag
    mov [hit_id], eax
    call raise_window
    cmp eax, TERM_COUNT
    jae .win_raised
    call set_active_term
.win_raised:
    mov byte [content_dirty], 1
    mov eax, [hit_id]
    call hit_buttons
    cmp dword [btn_hit], 0
    je .maybe_resize
    call do_button
    jmp .drag
.maybe_resize:
    mov eax, [hit_id]
    cmp byte [win_zoom + eax], 0
    jne .title
    call resize_hit
    jc .title
    mov byte [resizing], 1
    mov eax, [hit_id]
    mov [resize_id], eax
    mov ebx, eax
    shl ebx, 2
    mov eax, [mouse_x]
    mov [resize_ox], eax
    mov eax, [mouse_y]
    mov [resize_oy], eax
    mov eax, [win_w + ebx]
    mov [resize_ow], eax
    mov eax, [win_h + ebx]
    mov [resize_oh], eax
    jmp .drag
.title:
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
    mov byte [resizing], 0
.drag:
    cmp byte [resizing], 0
    je .maybe_move
    cmp byte [mouse_moved], 0
    je .out
    mov eax, [resize_id]
    mov ebx, eax
    shl ebx, 2
    mov eax, [mouse_x]
    sub eax, [resize_ox]
    add eax, [resize_ow]
    cmp eax, MIN_WIN_W
    jge .w_min
    mov eax, MIN_WIN_W
.w_min:
    mov ecx, SCREEN_W
    sub ecx, [win_x + ebx]
    cmp eax, ecx
    jle .w_max
    mov eax, ecx
.w_max:
    cmp eax, MIN_WIN_W
    jge .w_ok
    mov eax, MIN_WIN_W
.w_ok:
    mov [win_w + ebx], eax
    mov eax, [mouse_y]
    sub eax, [resize_oy]
    add eax, [resize_oh]
    cmp eax, MIN_WIN_H
    jge .h_min
    mov eax, MIN_WIN_H
.h_min:
    mov ecx, DOCK_Y
    sub ecx, [win_y + ebx]
    cmp eax, ecx
    jle .h_max
    mov eax, ecx
.h_max:
    cmp eax, MIN_WIN_H
    jge .h_ok
    mov eax, MIN_WIN_H
.h_ok:
    mov [win_h + ebx], eax
    call clamp_window
    mov byte [content_dirty], 1
    jmp .out
.maybe_move:
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
    mov byte [content_dirty], 1
.out:
    mov byte [mouse_moved], 0
    popad
    ret

; EAX = window id. CF = 0 when pointer is in the bottom-right resize zone.
resize_hit:
    push ebx
    push ecx
    push edx
    mov ebx, eax
    shl ebx, 2
    mov ecx, [win_x + ebx]
    add ecx, [win_w + ebx]
    sub ecx, RESIZE_ZONE
    mov edx, [mouse_x]
    cmp edx, ecx
    jl .no
    mov ecx, [win_x + ebx]
    add ecx, [win_w + ebx]
    cmp edx, ecx
    jge .no
    mov ecx, [win_y + ebx]
    add ecx, [win_h + ebx]
    sub ecx, RESIZE_ZONE
    mov edx, [mouse_y]
    cmp edx, ecx
    jl .no
    mov ecx, [win_y + ebx]
    add ecx, [win_h + ebx]
    cmp edx, ecx
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
    cmp byte [win_vis + eax], 0
    je .next
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

; EAX = menu id 1..4, or 0.
hit_menubar:
    push ebx
    mov ebx, [mouse_y]
    cmp ebx, MENU_H
    jge .none
    mov ebx, [mouse_x]
    cmp ebx, MENU_FILE_X
    jl .none
    cmp ebx, MENU_FILE_X + MENU_ITEM_W
    jl .file
    cmp ebx, MENU_EDIT_X
    jl .none
    cmp ebx, MENU_EDIT_X + MENU_ITEM_W
    jl .edit
    cmp ebx, MENU_VIEW_X
    jl .none
    cmp ebx, MENU_VIEW_X + MENU_ITEM_W
    jl .view
    cmp ebx, MENU_WIN_X
    jl .none
    cmp ebx, MENU_WIN_X + MENU_WIN_W
    jl .win
.none:
    xor eax, eax
    pop ebx
    ret
.file:
    mov eax, 1
    pop ebx
    ret
.edit:
    mov eax, 2
    pop ebx
    ret
.view:
    mov eax, 3
    pop ebx
    ret
.win:
    mov eax, 4
    pop ebx
    ret

; EAX = item index 0..1, or -1. Uses menu_open.
hit_dropdown:
    push ebx
    push ecx
    push edx
    movzx eax, byte [menu_open]
    test eax, eax
    jz .miss
    call menu_xy
    mov ecx, eax
    mov edx, ebx
    mov eax, [mouse_x]
    cmp eax, ecx
    jl .miss
    add ecx, DROP_W
    cmp eax, ecx
    jge .miss
    mov eax, [mouse_y]
    cmp eax, edx
    jl .miss
    mov ebx, edx
    add ebx, DROP_H * 2
    cmp eax, ebx
    jge .miss
    sub eax, edx
    xor edx, edx
    mov ebx, DROP_H
    div ebx
    pop edx
    pop ecx
    pop ebx
    ret
.miss:
    mov eax, -1
    pop edx
    pop ecx
    pop ebx
    ret

; Sets EAX=x, EBX=y for open menu.
menu_xy:
    movzx eax, byte [menu_open]
    cmp eax, 1
    je .f
    cmp eax, 2
    je .e
    cmp eax, 3
    je .v
    mov eax, MENU_WIN_X
    jmp .y
.f:
    mov eax, MENU_FILE_X
    jmp .y
.e:
    mov eax, MENU_EDIT_X
    jmp .y
.v:
    mov eax, MENU_VIEW_X
.y:
    mov ebx, MENU_H
    ret

; EAX = item index.
menu_action:
    pushad
    movzx ebx, byte [menu_open]
    cmp ebx, 1
    je .file
    cmp ebx, 2
    je .edit
    cmp ebx, 3
    je .view
    cmp ebx, 4
    je .win
    jmp .done
.file:
    test eax, eax
    jnz .close
    call new_terminal
    jmp .done
.close:
    call front_visible
    cmp eax, 0
    jl .done
    mov byte [win_vis + eax], 0
    jmp .done
.edit:
    test eax, eax
    jnz .done
    call focus_front_term
    call term_clear
    mov dword [line_len], 0
    mov byte [line_buf], 0
    call shell_prompt
    jmp .done
.view:
    test eax, eax
    jnz .showall
    call front_visible
    cmp eax, 0
    jl .done
    mov [hit_id], eax
    mov dword [btn_hit], 3
    call do_button
    jmp .done
.showall:
    mov ecx, WIN_COUNT
.show:
    dec ecx
    js .done
    mov byte [win_vis + ecx], 1
    jmp .show
.win:
    test eax, eax
    jnz .about
    xor eax, eax
    mov byte [win_vis], 1
    call raise_window
    call set_active_term
    jmp .done
.about:
    mov eax, ABOUT_ID
    mov byte [win_vis + ABOUT_ID], 1
    call raise_window
.done:
    popad
    ret

; Frontmost visible window, or EAX = -1.
front_visible:
    push ecx
    mov ecx, WIN_COUNT
.next:
    dec ecx
    js .none
    movzx eax, byte [win_z + ecx]
    cmp byte [win_vis + eax], 0
    je .next
    pop ecx
    ret
.none:
    mov eax, -1
    pop ecx
    ret

; Make the frontmost visible terminal the active I/O target.
focus_front_term:
    push eax
    push ecx
    mov ecx, WIN_COUNT
.next:
    dec ecx
    js .out
    movzx eax, byte [win_z + ecx]
    cmp eax, TERM_COUNT
    jae .next
    cmp byte [win_vis + eax], 0
    je .next
    call set_active_term
.out:
    pop ecx
    pop eax
    ret

; EAX = terminal id. Saves the previous line buffer and loads this one.
set_active_term:
    pushad
    cmp eax, TERM_COUNT
    jae .out
    cmp eax, [active_term]
    je .out
    mov ebx, [active_term]
    mov ecx, [line_len]
    mov [term_llens + ebx * 4], ecx
    imul ebx, LINE_STRIDE
    mov esi, line_buf
    lea edi, [term_lines + ebx]
    mov ecx, LINE_STRIDE
    cld
    rep movsb
    mov [active_term], eax
    mov ebx, eax
    mov ecx, [term_llens + ebx * 4]
    mov [line_len], ecx
    imul ebx, LINE_STRIDE
    lea esi, [term_lines + ebx]
    mov edi, line_buf
    mov ecx, LINE_STRIDE
    rep movsb
.out:
    popad
    ret

; Open another Terminal window from the pool.
new_terminal:
    pushad
    xor ecx, ecx
.find:
    cmp ecx, TERM_COUNT
    jae .reuse
    cmp byte [win_vis + ecx], 0
    je .found
    inc ecx
    jmp .find
.reuse:
    mov ecx, 1
    cmp dword [active_term], 1
    jne .found
    mov ecx, 2
.found:
    mov eax, ecx
    mov byte [win_vis + eax], 1
    mov byte [win_zoom + eax], 0
    mov ebx, eax
    shl ebx, 2
    mov edx, eax
    imul edx, 20
    add edx, 24
    mov [win_x + ebx], edx
    mov edx, eax
    imul edx, 18
    add edx, 30
    mov [win_y + ebx], edx
    mov dword [win_w + ebx], TERM_W
    mov dword [win_h + ebx], TERM_H
    call clamp_window
    call raise_window
    call set_active_term
    call term_clear
    mov dword [line_len], 0
    mov byte [line_buf], 0
    call shell_prompt
    mov byte [content_dirty], 1
    popad
    ret

; EAX = window id. Sets btn_hit to 1/2/3 or 0.
hit_buttons:
    push ebx
    push ecx
    push edx
    mov dword [btn_hit], 0
    mov ebx, eax
    shl ebx, 2
    mov ecx, [win_y + ebx]
    add ecx, TITLE_H / 2
    mov edx, [mouse_y]
    sub edx, ecx
    cmp edx, -BTN_R
    jl .no
    cmp edx, BTN_R
    jg .no
    mov ecx, [win_x + ebx]
    add ecx, 12
    mov edx, [mouse_x]
    sub edx, ecx
    cmp edx, -BTN_R
    jl .try_y
    cmp edx, BTN_R
    jg .try_y
    mov dword [btn_hit], 1
    jmp .no
.try_y:
    add ecx, 14
    mov edx, [mouse_x]
    sub edx, ecx
    cmp edx, -BTN_R
    jl .try_g
    cmp edx, BTN_R
    jg .try_g
    mov dword [btn_hit], 2
    jmp .no
.try_g:
    add ecx, 14
    mov edx, [mouse_x]
    sub edx, ecx
    cmp edx, -BTN_R
    jl .no
    cmp edx, BTN_R
    jg .no
    mov dword [btn_hit], 3
.no:
    pop edx
    pop ecx
    pop ebx
    ret

do_button:
    pushad
    mov eax, [hit_id]
    mov ebx, [btn_hit]
    cmp ebx, 1
    je .close
    cmp ebx, 2
    je .min
    cmp ebx, 3
    je .zoom
    jmp .done
.close:
    mov byte [win_vis + eax], 0
    mov byte [content_dirty], 1
    jmp .done
.min:
    mov byte [win_vis + eax], 0
    mov byte [content_dirty], 1
    jmp .done
.zoom:
    mov ebx, eax
    shl ebx, 2
    cmp byte [win_zoom + eax], 0
    jne .restore
    mov ecx, [win_x + ebx]
    mov [win_sx + ebx], ecx
    mov ecx, [win_y + ebx]
    mov [win_sy + ebx], ecx
    mov ecx, [win_w + ebx]
    mov [win_sw + ebx], ecx
    mov ecx, [win_h + ebx]
    mov [win_sh + ebx], ecx
    mov dword [win_x + ebx], 0
    mov dword [win_y + ebx], MENU_H
    mov dword [win_w + ebx], SCREEN_W
    mov ecx, DOCK_Y
    sub ecx, MENU_H
    mov [win_h + ebx], ecx
    mov byte [win_zoom + eax], 1
    mov byte [content_dirty], 1
    jmp .done
.restore:
    mov ecx, [win_sx + ebx]
    mov [win_x + ebx], ecx
    mov ecx, [win_sy + ebx]
    mov [win_y + ebx], ecx
    mov ecx, [win_sw + ebx]
    mov [win_w + ebx], ecx
    mov ecx, [win_sh + ebx]
    mov [win_h + ebx], ecx
    mov byte [win_zoom + eax], 0
    mov byte [content_dirty], 1
.done:
    popad
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
    mov eax, [win_w + ebx]
    cmp eax, MIN_WIN_W
    jge .w_lo
    mov eax, MIN_WIN_W
    mov [win_w + ebx], eax
.w_lo:
    mov ecx, SCREEN_W
    cmp eax, ecx
    jle .w_hi
    mov [win_w + ebx], ecx
.w_hi:
    mov eax, [win_h + ebx]
    cmp eax, MIN_WIN_H
    jge .h_lo
    mov eax, MIN_WIN_H
    mov [win_h + ebx], eax
.h_lo:
    mov ecx, DOCK_Y
    sub ecx, TOP_H
    cmp eax, ecx
    jle .h_hi
    mov [win_h + ebx], ecx
.h_hi:
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
    mov ecx, DOCK_Y
    sub ecx, [win_h + ebx]
    cmp ecx, TOP_H
    jge .y_lim
    mov ecx, TOP_H
.y_lim:
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
    cmp dword [fb_front], 0
    je .out
    mov eax, [fb_back]
    mov [fb_target], eax
    mov byte [content_dirty], 0
    mov byte [cursor_dirty], 0
    call draw_wallpaper
    call draw_menu
    xor ecx, ecx
.wins:
    cmp ecx, WIN_COUNT
    jae .dock
    movzx eax, byte [win_z + ecx]
    cmp byte [win_vis + eax], 0
    je .skip_win
    push ecx
    call draw_window
    pop ecx
.skip_win:
    inc ecx
    jmp .wins
.dock:
    call draw_dock
    call draw_dropdown
    call present
    mov byte [have_cursor], 0
    call move_cursor
.out:
    popad
    ret

draw_wallpaper:
    push eax
    push ebx
    push ecx
    push edx
    xor ecx, ecx
.row:
    cmp ecx, SCREEN_H
    jge .done
    mov eax, ecx
    imul eax, 54
    xor edx, edx
    mov ebx, SCREEN_H
    div ebx
    mov ebx, 78
    sub ebx, eax
    mov [wall_r], bl
    mov eax, ecx
    imul eax, 96
    xor edx, edx
    mov ebx, SCREEN_H
    div ebx
    mov ebx, 156
    sub ebx, eax
    mov [wall_g], bl
    mov eax, ecx
    imul eax, 100
    xor edx, edx
    mov ebx, SCREEN_H
    div ebx
    mov ebx, 214
    sub ebx, eax
    mov [wall_b], bl
    mov al, [wall_r]
    mov ah, [wall_g]
    mov bl, [wall_b]
    push ecx
    call pack_rgb
    pop ecx
    FILL 0, ecx, SCREEN_W, 1, eax
    inc ecx
    jmp .row
.done:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

wall_r db 0
wall_g db 0
wall_b db 0

draw_menu:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    FILL 0, 0, SCREEN_W, MENU_H, [col_menu]
    cmp byte [menu_open], 1
    jne .hf
    FILL MENU_FILE_X, 0, MENU_ITEM_W, MENU_H, [col_menu_hi]
.hf:
    cmp byte [menu_open], 2
    jne .he
    FILL MENU_EDIT_X, 0, MENU_ITEM_W, MENU_H, [col_menu_hi]
.he:
    cmp byte [menu_open], 3
    jne .hv
    FILL MENU_VIEW_X, 0, MENU_ITEM_W, MENU_H, [col_menu_hi]
.hv:
    cmp byte [menu_open], 4
    jne .hw
    FILL MENU_WIN_X, 0, MENU_WIN_W, MENU_H, [col_menu_hi]
.hw:
    mov eax, 6
    mov ebx, TEXT_DY
    mov esi, bar_title
    mov edx, [col_white]
    mov ecx, -1
    call draw_string
    mov eax, MENU_FILE_X + 2
    mov ebx, TEXT_DY
    mov esi, menu_file
    mov edx, [col_menu_dim]
    cmp byte [menu_open], 1
    jne .f
    mov edx, [col_white]
.f:
    mov ecx, -1
    call draw_string
    mov eax, MENU_EDIT_X + 2
    mov esi, menu_edit
    mov edx, [col_menu_dim]
    cmp byte [menu_open], 2
    jne .e
    mov edx, [col_white]
.e:
    call draw_string
    mov eax, MENU_VIEW_X + 2
    mov esi, menu_view
    mov edx, [col_menu_dim]
    cmp byte [menu_open], 3
    jne .v
    mov edx, [col_white]
.v:
    call draw_string
    mov eax, MENU_WIN_X + 2
    mov esi, menu_window
    mov edx, [col_menu_dim]
    cmp byte [menu_open], 4
    jne .w
    mov edx, [col_white]
.w:
    call draw_string
    mov eax, CLOCK_X
    mov ebx, TEXT_DY
    mov esi, clock_str
    mov edx, [col_white]
    mov ecx, -1
    call draw_string
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

draw_dropdown:
    pushad
    cmp byte [menu_open], 0
    je .out
    call menu_xy
    mov [origin_x], eax
    mov [origin_y], ebx
    FILL eax, ebx, DROP_W, DROP_H * 2, [col_win]
    FILL eax, ebx, DROP_W, 1, [col_line]
    movzx eax, byte [menu_open]
    cmp eax, 1
    je .file
    cmp eax, 2
    je .edit
    cmp eax, 3
    je .view
    mov esi, title_term
    mov edi, title_about
    jmp .items
.file:
    mov esi, item_new
    mov edi, item_close
    jmp .items
.edit:
    mov esi, item_clear
    mov edi, item_copy
    jmp .items
.view:
    mov esi, item_zoom
    mov edi, item_show
.items:
    mov eax, [origin_x]
    add eax, 8
    mov ebx, [origin_y]
    add ebx, 2
    mov edx, [col_ink]
    mov ecx, -1
    call draw_string
    mov esi, edi
    mov eax, [origin_x]
    add eax, 8
    mov ebx, [origin_y]
    add ebx, DROP_H + 2
    cmp byte [menu_open], 2
    jne .ink2
    mov edx, [col_menu_dim]
.ink2:
    call draw_string
.out:
    popad
    ret

draw_dock:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    xor ecx, ecx
.row:
    cmp ecx, DOCK_H
    jge .icons
    xor eax, eax
    cmp ecx, 6
    jge .bot
    mov eax, 6
    sub eax, ecx
    jmp .fill
.bot:
    mov ebx, DOCK_H
    sub ebx, ecx
    cmp ebx, 6
    jge .fill
    mov eax, 6
    sub eax, ebx
.fill:
    mov edx, DOCK_W
    sub edx, eax
    sub edx, eax
    mov esi, DOCK_X
    add esi, eax
    mov ebx, DOCK_Y
    add ebx, ecx
    FILL esi, ebx, edx, 1, [col_dock]
    inc ecx
    jmp .row
.icons:
    FILL ICON0_X, ICON_Y, ICON, ICON, [col_icon_term]
    FILL ICON0_X + 3, ICON_Y + 4, 18, 14, [col_black]
    FILL ICON0_X + 5, ICON_Y + 6, 2, 2, [col_green]
    FILL ICON0_X + 7, ICON_Y + 8, 2, 2, [col_green]
    FILL ICON0_X + 9, ICON_Y + 10, 2, 2, [col_green]
    FILL ICON0_X + 7, ICON_Y + 12, 2, 2, [col_green]
    FILL ICON0_X + 5, ICON_Y + 14, 2, 2, [col_green]
    FILL ICON0_X + 12, ICON_Y + 14, 6, 2, [col_green]
    FILL ICON1_X, ICON_Y, ICON, ICON, [col_icon_about]
    mov eax, ICON1_X + ICON / 2
    mov ebx, ICON_Y + ICON / 2
    mov ecx, 6
    mov edx, [col_white]
    call draw_disc
    mov eax, ICON1_X + ICON / 2 - 1
    mov ebx, ICON_Y + 7
    FILL eax, ebx, 2, 2, [col_icon_about]
    add ebx, 4
    FILL eax, ebx, 2, 7, [col_icon_about]
    cmp byte [win_vis], 0
    je .about_dot
    FILL ICON0_X + 8, ICON_Y + ICON + 1, 8, 2, [col_white]
.about_dot:
    cmp byte [win_vis + ABOUT_ID], 0
    je .done_icons
    FILL ICON1_X + 8, ICON_Y + ICON + 1, 8, 2, [col_white]
.done_icons:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; EAX = primary Terminal or About id when on a dock icon, else -1.
hit_dock:
    push ebx
    mov ebx, [mouse_y]
    cmp ebx, ICON_Y
    jl .no
    mov eax, ICON_Y + ICON
    cmp ebx, eax
    jge .no
    mov ebx, [mouse_x]
    cmp ebx, ICON0_X
    jl .no
    mov eax, ICON0_X + ICON
    cmp ebx, eax
    jl .term
    cmp ebx, ICON1_X
    jl .no
    mov eax, ICON1_X + ICON
    cmp ebx, eax
    jl .about
.no:
    mov eax, -1
    pop ebx
    ret
.term:
    xor eax, eax
    pop ebx
    ret
.about:
    mov eax, ABOUT_ID
    pop ebx
    ret

; EAX = window id.
draw_window:
    pushad
    mov [win_draw_id], eax
    mov ebx, eax
    shl ebx, 2

    mov eax, [win_x + ebx]
    sub eax, 4
    mov ecx, [win_y + ebx]
    add ecx, 6
    mov edx, [win_w + ebx]
    add edx, 8
    mov esi, [win_h + ebx]
    sub esi, 4
    FILL eax, ecx, edx, esi, [col_shadow]

    FILL [win_x + ebx], [win_y + ebx], [win_w + ebx], [win_h + ebx], [col_border]

    mov eax, [win_x + ebx]
    add eax, BORDER
    mov ecx, [win_y + ebx]
    add ecx, BORDER
    mov edx, [win_w + ebx]
    sub edx, BORDER * 2
    mov esi, [win_h + ebx]
    sub esi, BORDER * 2
    mov edi, [col_title_dim]
    push eax
    mov al, [win_z + WIN_COUNT - 1]
    cmp al, [win_draw_id]
    pop eax
    jne .body
    mov edi, [col_win]
.body:
    FILL eax, ecx, edx, esi, edi

    mov eax, [win_x + ebx]
    add eax, BORDER
    mov ecx, [win_y + ebx]
    add ecx, TITLE_H
    mov edx, [win_w + ebx]
    sub edx, BORDER * 2
    FILL eax, ecx, edx, 1, [col_line]

    mov eax, [win_draw_id]
    cmp byte [win_kind + eax], 0
    jne .about
    call draw_terminal
    jmp .chrome
.about:
    call draw_about
.chrome:
    mov eax, [win_x + ebx]
    add eax, 12
    mov ecx, [win_y + ebx]
    add ecx, TITLE_H / 2
    mov edx, [col_red]
    push ebx
    mov ebx, ecx
    mov ecx, BTN_R
    call draw_disc
    add eax, 14
    mov edx, [col_yellow]
    call draw_disc
    add eax, 14
    mov edx, [col_green]
    call draw_disc
    pop ebx

    mov esi, [win_title + ebx]
    mov eax, [win_x + ebx]
    add eax, 52
    mov ecx, [win_y + ebx]
    add ecx, TEXT_DY
    mov edx, [col_ink]
    push eax
    mov al, [win_draw_id]
    cmp al, [win_z + WIN_COUNT - 1]
    pop eax
    je .title
    mov edx, [col_menu_dim]
.title:
    mov ebx, ecx
    mov ecx, -1
    call draw_string
    popad
    ret

; ESI = string. EAX = length.
str_len:
    push esi
    xor eax, eax
.more:
    cmp byte [esi + eax], 0
    je .done
    inc eax
    jmp .more
.done:
    pop esi
    ret

; EAX = cx, EBX = cy, ECX = radius, EDX = color.
draw_disc:
    pushad
    mov [disc_cx], eax
    mov [disc_cy], ebx
    mov [disc_r], ecx
    mov [disc_col], edx
    mov ecx, [disc_r]
    neg ecx
.dy:
    cmp ecx, [disc_r]
    jg .done
    mov edx, [disc_r]
    neg edx
.dx:
    cmp edx, [disc_r]
    jg .next_y
    mov eax, ecx
    imul eax, eax
    mov ebx, edx
    imul ebx, ebx
    add eax, ebx
    mov ebx, [disc_r]
    imul ebx, ebx
    cmp eax, ebx
    jg .skip
    mov eax, [disc_cx]
    add eax, edx
    mov ebx, [disc_cy]
    add ebx, ecx
    push ecx
    push edx
    mov edx, [disc_col]
    call put_pixel
    pop edx
    pop ecx
.skip:
    inc edx
    jmp .dx
.next_y:
    inc ecx
    jmp .dy
.done:
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
    FILL [origin_x], [origin_y], TERM_COLS * FONT, TERM_ROWS * FONT_H, edx

    movzx eax, byte [vga_attr]
    and eax, 0x0F
    mov eax, [vga_pal + eax * 4]
    mov [term_fg], eax

    mov eax, [win_draw_id]
    imul eax, TERM_CELLS
    lea esi, [term_bufs + eax]

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
    movzx eax, byte [esi + eax]
    cmp al, ' '
    je .next_col
    mov [cell_col], ebx
    mov [cell_row], ecx
    movzx edi, al
    mov eax, ebx
    imul eax, FONT
    add eax, [origin_x]
    mov edx, ecx
    imul edx, FONT_H
    add edx, [origin_y]
    mov ebx, edx
    push esi
    push dword -1
    push dword [term_fg]
    push edi
    push ebx
    push eax
    call draw_char
    add esp, 20
    pop esi
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
    mov eax, [win_draw_id]
    shl eax, 2
    mov ebx, [win_x + eax]
    add ebx, BORDER + PAD
    mov ecx, [win_y + eax]
    add ecx, TITLE_H + PAD
    mov eax, ebx
    mov ebx, ecx
    mov edx, [col_ink]
    mov ecx, -1
    mov esi, about_l1
    call draw_string
    add ebx, 18
    mov esi, about_l2
    call draw_string
    add ebx, 18
    mov esi, about_l3
    call draw_string
    add ebx, 18
    mov esi, about_l4
    call draw_string
    add ebx, 18
    mov esi, about_l5
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
; 8x16 glyphs. Bit 0 of each font row is the leftmost pixel.
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
    mov al, bl
    shr al, 1
    or bl, al
    xor edx, edx
.col:
    cmp edx, 8
    jge .next_row
    test bl, 1
    jnz .fg
    cmp dword [ebp + 52], -1
    je .advance
    mov edi, [ebp + 52]
    jmp .pix
.fg:
    mov edi, [ebp + 48]
.pix:
    push ebx
    push ecx
    push edx
    mov eax, [ebp + 36]
    add eax, edx
    mov ebx, ecx
    shl ebx, 1
    add ebx, [ebp + 40]
    mov edx, edi
    call put_pixel
    inc ebx
    call put_pixel
    pop edx
    pop ecx
    pop ebx
.advance:
    shr bl, 1
    inc edx
    jmp .col
.next_row:
    inc ecx
    jmp .row
.done:
    popad
    ret

present:
    pushad
    cld
    mov esi, [fb_back]
    mov edi, [fb_front]
    mov ebx, SCREEN_H
.row:
    mov ecx, SCREEN_W
    rep movsd
    mov eax, [fb_pitch]
    sub eax, SCREEN_W * 4
    add esi, eax
    add edi, eax
    dec ebx
    jnz .row
    popad
    ret

move_cursor:
    pushad
    cli
    cmp byte [have_cursor], 0
    je .save
    mov eax, [mouse_x]
    cmp eax, [cur_x]
    jne .restore
    mov eax, [mouse_y]
    cmp eax, [cur_y]
    je .draw
.restore:
    call restore_under
.save:
    mov eax, [mouse_x]
    mov [cur_x], eax
    mov eax, [mouse_y]
    mov [cur_y], eax
    call save_under
    mov byte [have_cursor], 1
.draw:
    mov eax, [fb_front]
    mov [fb_target], eax
    call draw_cursor
    mov eax, [fb_back]
    mov [fb_target], eax
    sti
    popad
    ret

save_under:
    pushad
    cld
    mov eax, [cur_x]
    mov ebx, [cur_y]
    mov ecx, CUR_S
    mov edx, SCREEN_W
    sub edx, eax
    cmp ecx, edx
    jle .w_ok
    mov ecx, edx
.w_ok:
    mov [cur_w], ecx
    mov ecx, CUR_S
    mov edx, SCREEN_H
    sub edx, ebx
    cmp ecx, edx
    jle .h_ok
    mov ecx, edx
.h_ok:
    mov [cur_h], ecx
    mov esi, [fb_front]
    mov eax, [cur_y]
    imul eax, [fb_pitch]
    add esi, eax
    mov eax, [cur_x]
    shl eax, 2
    add esi, eax
    mov edi, cursor_bg
    mov ebx, [cur_h]
.copy:
    push esi
    mov ecx, [cur_w]
    rep movsd
    pop esi
    add esi, [fb_pitch]
    dec ebx
    jnz .copy
    popad
    ret

restore_under:
    pushad
    cld
    mov edi, [fb_front]
    mov eax, [cur_y]
    imul eax, [fb_pitch]
    add edi, eax
    mov eax, [cur_x]
    shl eax, 2
    add edi, eax
    mov esi, cursor_bg
    mov ebx, [cur_h]
.copy:
    push edi
    mov ecx, [cur_w]
    rep movsd
    pop edi
    add edi, [fb_pitch]
    dec ebx
    jnz .copy
    popad
    ret

read_clock:
    push eax
    push ebx
    push edi
    mov edi, clock_str
    mov al, 0x04
    call cmos_read
    and al, 0x3F
    call bcd_to_bin
    mov bl, al
    cmp bl, 12
    jb .am
    mov byte [clock_str + 6], 'P'
    cmp bl, 12
    je .hour
    sub bl, 12
    jmp .hour
.am:
    mov byte [clock_str + 6], 'A'
    test bl, bl
    jnz .hour
    mov bl, 12
.hour:
    mov al, bl
    cmp al, 10
    jae .two
    mov byte [edi], ' '
    inc edi
    add al, '0'
    stosb
    jmp .min
.two:
    call store_bin2
.min:
    mov al, ':'
    stosb
    mov al, 0x02
    call cmos_read
    call store_bcd
    mov al, ' '
    stosb
    mov al, [clock_str + 6]
    stosb
    mov al, 'M'
    stosb
    mov byte [edi], 0
    pop edi
    pop ebx
    pop eax
    ret

; AL = CMOS index. Returns AL = data.
cmos_read:
    or al, 0x80
    out 0x70, al
    in al, 0x71
    ret

; AL = BCD -> binary.
bcd_to_bin:
    push ebx
    mov bl, al
    and al, 0x0F
    shr bl, 4
    mov bh, 10
    movzx ebx, bl
    imul ebx, 10
    add al, bl
    pop ebx
    ret

; AL = binary 0..99, writes two digits at EDI.
store_bin2:
    push eax
    push ebx
    xor ah, ah
    mov bl, 10
    div bl
    add al, '0'
    stosb
    mov al, ah
    add al, '0'
    stosb
    pop ebx
    pop eax
    ret

; AL = BCD, writes two digits at EDI.
store_bcd:
    push eax
    shr al, 4
    and al, 0x0F
    add al, '0'
    stosb
    pop eax
    and al, 0x0F
    add al, '0'
    stosb
    ret

clock_poll:
    pushad
    mov eax, [timer_ticks]
    sub eax, [clock_stamp]
    cmp eax, 18
    jb .done
    mov eax, [timer_ticks]
    mov [clock_stamp], eax
    call read_clock
    mov esi, clock_str
    mov edi, clock_prev
    mov ecx, 8
    cld
    repe cmpsb
    je .done
    mov esi, clock_str
    mov edi, clock_prev
    mov ecx, 8
    rep movsb
    mov byte [content_dirty], 1
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
    add edi, [fb_target]
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
    add edi, [fb_target]
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
    COLOR col_border, 210, 210, 216
    COLOR col_white, 255, 255, 255
    COLOR col_black, 0, 0, 0
    COLOR col_ink, 28, 28, 30
    COLOR col_menu, 32, 32, 34
    COLOR col_menu_dim, 176, 176, 184
    COLOR col_menu_hi, 70, 70, 78
    COLOR col_dock, 46, 46, 50
    COLOR col_shadow, 10, 22, 40
    COLOR col_line, 198, 198, 204
    COLOR col_red, 255, 95, 87
    COLOR col_yellow, 254, 188, 46
    COLOR col_green, 40, 200, 64
    COLOR col_icon_term, 28, 28, 32
    COLOR col_icon_about, 36, 110, 196
    COLOR col_win, 245, 245, 247
    COLOR col_title_dim, 232, 232, 236
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

; Active terminal buffer helpers.
; Sets EDI to the active terminal buffer. Preserves EAX (character in AL).
term_active_buf:
    push eax
    mov eax, [active_term]
    imul eax, TERM_CELLS
    lea edi, [term_bufs + eax]
    pop eax
    ret

term_clear:
    push eax
    push ecx
    push edi
    call term_active_buf
    mov ecx, TERM_CELLS
    mov al, ' '
    cld
    rep stosb
    mov eax, [active_term]
    mov dword [term_col_arr + eax * 4], 0
    mov dword [term_row_arr + eax * 4], 0
    mov byte [content_dirty], 1
    pop edi
    pop ecx
    pop eax
    ret

term_putc:
    push eax
    push ebx
    push ecx
    push edi
    cmp al, 13
    je .out
    cmp al, 10
    je .nl
    call term_active_buf
    mov ebx, [active_term]
    mov ecx, [term_row_arr + ebx * 4]
    imul ecx, TERM_COLS
    add ecx, [term_col_arr + ebx * 4]
    mov [edi + ecx], al
    inc dword [term_col_arr + ebx * 4]
    cmp dword [term_col_arr + ebx * 4], TERM_COLS
    jb .mark
.nl:
    mov ebx, [active_term]
    mov dword [term_col_arr + ebx * 4], 0
    inc dword [term_row_arr + ebx * 4]
    cmp dword [term_row_arr + ebx * 4], TERM_ROWS
    jb .mark
    call term_scroll
    mov ebx, [active_term]
    mov dword [term_row_arr + ebx * 4], TERM_ROWS - 1
.mark:
    mov byte [content_dirty], 1
.out:
    pop edi
    pop ecx
    pop ebx
    pop eax
    ret

term_backspace:
    push ebx
    push ecx
    push edi
    mov ebx, [active_term]
    cmp dword [term_col_arr + ebx * 4], 0
    jne .left
    cmp dword [term_row_arr + ebx * 4], 0
    je .out
    dec dword [term_row_arr + ebx * 4]
    mov dword [term_col_arr + ebx * 4], TERM_COLS - 1
    jmp .wipe
.left:
    dec dword [term_col_arr + ebx * 4]
.wipe:
    call term_active_buf
    mov ebx, [active_term]
    mov ecx, [term_row_arr + ebx * 4]
    imul ecx, TERM_COLS
    add ecx, [term_col_arr + ebx * 4]
    mov byte [edi + ecx], ' '
    mov byte [content_dirty], 1
.out:
    pop edi
    pop ecx
    pop ebx
    ret

term_recolor:
    mov byte [content_dirty], 1
    ret

term_scroll:
    push eax
    push ebx
    push ecx
    push esi
    push edi
    call term_active_buf
    mov esi, edi
    add esi, TERM_COLS
    mov ecx, TERM_COLS * (TERM_ROWS - 1)
    cld
    rep movsb
    mov ecx, TERM_COLS
    mov al, ' '
    rep stosb
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret
