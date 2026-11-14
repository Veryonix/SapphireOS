; Line editor and the built-in commands.
LINE_MAX equ 69

line_buf times LINE_MAX + 1 db 0
line_len dd 0

banner:
    db "SapphireOS v0.1", 10
    db "---------------", 10
    db "32-bit protected mode", 10
    db 10, 0

prompt db "sapphire> ", 0

cmd_help db "help", 0
cmd_clear db "clear", 0
cmd_about db "about", 0
cmd_echo db "echo", 0
cmd_color db "color", 0
cmd_reboot db "reboot", 0

msg_help:
    db "Commands:", 10
    db "  help          show this help", 10
    db "  clear         clear the screen", 10
    db "  about         about SapphireOS", 10
    db "  echo TEXT     print TEXT", 10
    db "  color HH      set the VGA attribute", 10
    db "  reboot        reboot the machine", 10
    db 0

msg_about:
    db "SapphireOS v0.1", 10
    db "NASM kernel with a BIOS boot sector, a VBE desktop, and a PS/2 shell.", 10
    db 0

msg_unknown db "Unknown command", 10, 0
msg_color_set db "Attribute set to ", 0
msg_color_usage db "Usage: color HH", 10, 0
msg_reboot db "Rebooting...", 10, 0

shell_main:
    call shell_init
.loop:
    cli
    call kbuf_pop
    jnc .have
    sti
    hlt
    jmp .loop
.have:
    sti
    call shell_on_char
    jmp .loop

shell_init:
    call con_clear
    mov esi, banner
    call con_puts
    call shell_prompt
    ret

shell_prompt:
    push esi
    mov esi, prompt
    call con_puts
    pop esi
    ret

; AL = ASCII, 8 = backspace, 10 = enter.
shell_on_char:
    cmp al, 10
    je .enter
    cmp al, 8
    je .bs
    cmp al, ' '
    jb .ret
    cmp al, '~'
    ja .ret
    mov ebx, [line_len]
    cmp ebx, LINE_MAX
    jae .ret
    mov [line_buf + ebx], al
    inc ebx
    mov [line_len], ebx
    mov byte [line_buf + ebx], 0
    call con_putc
    ret
.bs:
    cmp dword [line_len], 0
    je .ret
    dec dword [line_len]
    mov ebx, [line_len]
    mov byte [line_buf + ebx], 0
    call con_backspace
    ret
.enter:
    call con_newline
    call shell_exec
    mov dword [line_len], 0
    mov byte [line_buf], 0
    call shell_prompt
.ret:
    ret

shell_exec:
    mov esi, line_buf
    call skip_spaces
    cmp byte [esi], 0
    je .done

    mov edi, cmd_help
    call cmd_eq
    jc .try_clear
    mov esi, msg_help
    call con_puts
    jmp .done
.try_clear:
    mov edi, cmd_clear
    call cmd_eq
    jc .try_about
    call con_clear
    jmp .done
.try_about:
    mov edi, cmd_about
    call cmd_eq
    jc .try_echo
    mov esi, msg_about
    call con_puts
    jmp .done
.try_echo:
    mov edi, cmd_echo
    call cmd_eq
    jc .try_color
    call do_echo
    jmp .done
.try_color:
    mov edi, cmd_color
    call cmd_eq
    jc .try_reboot
    call do_color
    jmp .done
.try_reboot:
    mov edi, cmd_reboot
    call cmd_eq
    jc .unknown
    call do_reboot
    jmp .done
.unknown:
    mov esi, msg_unknown
    call con_puts
.done:
    ret

do_echo:
    call skip_spaces
    cmp byte [esi], 0
    je .nl
    call con_puts
.nl:
    call con_newline
    ret

do_color:
    call skip_spaces
    cmp byte [esi], 0
    je .usage
    call parse_hex_byte
    jc .usage
    mov bl, al
    call skip_spaces
    cmp byte [esi], 0
    jne .usage
    mov [vga_attr], bl
    call con_recolor
    mov esi, msg_color_set
    call con_puts
    mov al, bl
    call con_put_hex8
    call con_newline
    ret
.usage:
    mov esi, msg_color_usage
    call con_puts
    ret

do_reboot:
    mov esi, msg_reboot
    call con_puts
    cli
.wait:
    in al, 0x64
    test al, 2
    jnz .wait
    mov al, 0xFE
    out 0x64, al
.hang:
    hlt
    jmp .hang

skip_spaces:
.loop:
    cmp byte [esi], ' '
    jne .done
    inc esi
    jmp .loop
.done:
    ret

; ESI = input, EDI = command. CF = 0 and ESI advanced on a whole-word match.
cmd_eq:
    push esi
    push edi
.cmp:
    mov al, [edi]
    test al, al
    jz .at_end
    cmp al, [esi]
    jne .no
    inc esi
    inc edi
    jmp .cmp
.at_end:
    mov al, [esi]
    cmp al, 0
    je .yes
    cmp al, ' '
    je .yes
.no:
    pop edi
    pop esi
    stc
    ret
.yes:
    pop edi
    add esp, 4
    clc
    ret

; Two hex digits at ESI. AL = value, ESI += 2, CF = 1 on error.
parse_hex_byte:
    mov al, [esi]
    call hex_value
    jc .bad
    shl al, 4
    mov ah, al
    mov al, [esi + 1]
    call hex_value
    jc .bad
    or al, ah
    add esi, 2
    clc
    ret
.bad:
    stc
    ret

hex_value:
    cmp al, '0'
    jb .no
    cmp al, '9'
    jbe .num
    cmp al, 'A'
    jb .lower
    cmp al, 'F'
    jbe .upper
.lower:
    cmp al, 'a'
    jb .no
    cmp al, 'f'
    ja .no
    sub al, 'a'
    add al, 10
    clc
    ret
.upper:
    sub al, 'A'
    add al, 10
    clc
    ret
.num:
    sub al, '0'
    clc
    ret
.no:
    stc
    ret
