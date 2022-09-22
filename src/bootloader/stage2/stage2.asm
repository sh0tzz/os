bits 16

section _ENTRY class=CODE

extern _cstart_
global entry

entry:
    cli
    mov ax, ds
    mov ss, ax
    mov sp, 0
    mov bp, sp
    sti

    ; xor dh, dh
    ; push dx
    ; call _cstart_

    cli
    hlt

GDT_START:
    null_descriptor:
        dq 0x0

    code_descriptor:
        dw 0xffff       ; limit
        dw 0x0          ; base
        db 0x0          ; word + byte = 24bits
        db 0b10011010   ; access byte
                        ; present   = 1     1 bit
                        ; defines valid segment
                        ; DPL       = 0     2 bits
                        ; defines privelige level
                        ; rings 0, 1, 2, 3
                        ; segment   = 1     1 bit
                        ; defines data/code segment
                        ; executable = 1    1 bit
                        ; defines code segment
                        ; conforming = 0    1 bit
                        ; defines not to conform to lower
                        ; privelige level
                        ; readable  = 1     1 bit
                        ; accessed  = 0     1 bit
        db 0b11101111   ; flags + limit(high)
                        ; granularity   = 1     flags 1 bit
                        ; 32bit mode    = 1     flags 1 bit
                        ; 64bit mode    = 1     flags 1 bit
                        ; reserved bit          flags 1 bit
                        ; limit high = max      limit 4 bits
        db 0x0          ; base high 8 bits

        

