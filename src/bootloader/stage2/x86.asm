bits 16

section _TEXT class=CODE

global _x86_Video_TeletypeOutput
_x86_Video_TeletypeOutput:
    ; function call frame on stack
    push bp     ; save old stack base
    mov bp, sp  ; create new substack

    ; save used registers
    push bx

    ; small memory model
    ; 2 byte aligned
    ; [bp + 2]  - return address
    ; [bp + 4]  - character to print
    ; [bp + 6]  - page

    ; VIDEO - TELETYPE OUTPUT
    ; int 0x10 / AH = 0x0E
    mov ah, 0x0E
    mov al, [bp + 4]
    mov bh, [bp + 6]
    int 0x10

    ; restore registers
    pop bx

    ; stack frame
    mov sp, bp  ; discard new stack frame
    pop bp      ; restore old stack frame

    ; return
    ret