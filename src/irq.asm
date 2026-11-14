; PIC remap and IDT. Hardware IRQs land at vectors 0x20-0x2F.
; Keyboard IRQ1 is vector 0x21. Mouse IRQ12 is vector 0x2C.

pic_remap:
    push eax
    push edx

    mov al, 0x11
    mov dx, 0x20
    out dx, al
    call io_wait
    mov dx, 0xA0
    out dx, al
    call io_wait

    mov al, 0x20
    mov dx, 0x21
    out dx, al
    call io_wait
    mov al, 0x28
    mov dx, 0xA1
    out dx, al
    call io_wait

    mov al, 0x04
    mov dx, 0x21
    out dx, al
    call io_wait
    mov al, 0x02
    mov dx, 0xA1
    out dx, al
    call io_wait

    mov al, 0x01
    mov dx, 0x21
    out dx, al
    call io_wait
    mov dx, 0xA1
    out dx, al
    call io_wait

    ; IRQ1 keyboard and IRQ2 cascade. IRQ12 is slave input 4.
    mov al, 0xF9
    mov dx, 0x21
    out dx, al
    mov al, 0xEF
    mov dx, 0xA1
    out dx, al

    pop edx
    pop eax
    ret

io_wait:
    push eax
    push edx
    mov dx, 0x80
    xor al, al
    out dx, al
    pop edx
    pop eax
    ret

idt_init:
    push eax
    push ebx
    push ecx
    push esi
    mov ecx, 256
    xor ebx, ebx
    mov esi, stub_table
.fill:
    mov eax, [esi]
    call idt_set_gate
    add esi, 4
    inc ebx
    loop .fill
    lidt [idt_ptr]
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret

; EAX = handler, EBX = vector.
idt_set_gate:
    push eax
    push edi
    mov edi, ebx
    shl edi, 3
    add edi, idt
    mov [edi], ax
    shr eax, 16
    mov word [edi + 2], CODE_SEG
    mov byte [edi + 4], 0
    mov byte [edi + 5], 0x8E
    mov [edi + 6], ax
    pop edi
    pop eax
    ret

isr_common:
    pushad
    mov ax, ds
    push eax

    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebx, [esp + 36]
    cmp ebx, 33
    jne .not_kbd
    call keyboard_handle
.not_kbd:
    cmp ebx, 44
    jne .not_mouse
    call mouse_handle
.not_mouse:
    cmp ebx, 32
    jb .exception
    cmp ebx, 40
    jb .eoi_master
    mov al, 0x20
    out 0xA0, al
.eoi_master:
    mov al, 0x20
    out 0x20, al

    pop eax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    popad
    add esp, 8
    iretd

.exception:
    cli
.hang:
    hlt
    jmp .hang

%macro ISR_STUB 1
%if (%1 = 8) || (%1 = 10) || (%1 = 11) || (%1 = 12) || (%1 = 13) || (%1 = 14) || (%1 = 17) || (%1 = 21) || (%1 = 29) || (%1 = 30)
isr_stub_%1:
    push dword %1
    jmp near isr_common
%else
isr_stub_%1:
    push dword 0
    push dword %1
    jmp near isr_common
%endif
%endmacro

%assign i 0
%rep 256
ISR_STUB i
%assign i i+1
%endrep

stub_table:
%assign i 0
%rep 256
    dd isr_stub_%+i
%assign i i+1
%endrep

align 8
idt:
    times 256 * 8 db 0
idt_end:

idt_ptr:
    dw idt_end - idt - 1
    dd idt
