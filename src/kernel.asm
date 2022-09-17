org 0x0
bits 16

%define ENDL 0x0D, 0x0A

start:
    mov si, msg
    call puts
    cli
    hlt

; prints string to BIOS out
; INPUT:
;   si    -   pointer to string
puts:
    push si
    push ax
    mov ah, 0x0e
_puts_loop:
    mov al, [si]
    cmp al, 0x00
    je _puts_end
    int 0x10
    inc si
    jmp _puts_loop
_puts_end:
    pop ax
    pop si
    ret

msg: db "KERNEL LOADS BABY", ENDL, 0