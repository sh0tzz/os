org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;
; FAT12 HEADER
;

jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0x0E0
bdb_total_sectors:          dw 2880
bdb_media_descriptor_type:  db 0x0F0
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0
; extended record
ebr_drive_number:           db 0
                            db 0
ebr_signature:              db 0x29
ebr_volume_id:              db 0x12, 0x34, 0x56, 0x78
ebr_volume_label            db 'WeAreL9 ?XD'
ebr_system_id:              db 'FAT12   '

start:
    ; intermediary register
    mov ax, 0
    ; data segment
    mov ds, ax
    mov es, ax
    ; stack segment
    mov ss, ax
    ; sp set to start of program in memory
    ; since stack grows backwards, memory before program is safe
    mov sp, 0x7C00
    ; push segment and location to stack and far return to
    ; because some BIOSes might go to 07C0:0000 instead of 0000:7C00
    push es
    push word _after_setup
    retf
_after_setup:
    ; read from floppy
    ; BIOS sets dl to drive number
    mov [ebr_drive_number], dl

    ; read drive params
    push es
    mov ah, 0x08
    int 0x13
    jc err_floppy
    pop es

    ; sector count
    and cl, 0x3F        ; slice top bits
    xor ch, ch
    mov [bdb_sectors_per_track], cx

    ; head count
    inc dh
    mov [bdb_heads], dh

    ; LBA of rootdir
    ; reserved_sectors + fat_count * sectors_per_fat
    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx
    add ax, [bdb_reserved_sectors]
    push ax

    ; size of rootdir
    ; 32 * entries_count / bytes_per_sector
    mov ax, [bdb_sectors_per_fat]
    shl ax, 5       ; ax *= 32
    xor dx, dx
    div word [bdb_bytes_per_sector]
    test dx, dx     ; round up
    jz _rootdir_after
    inc ax
_rootdir_after:

    ; read root directory
    mov cl, al                  ; read size => rootdir size
    pop ax                      ; earlier pushed LBA of rootdir
    mov dl, [ebr_drive_number]  ; load drive number given by BIOS
    mov bx, buffer
    call disk_read

    ; search for stage2.bin
    xor bx, bx
    mov di, buffer
_serach_file:
    mov si, file_stage2
    mov cx, 11              ; size of string in si
    push di
    repe cmpsb
    pop di
    je _found_file
    add di, 32
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl _serach_file
    ; failed
    jmp err_not_found
_found_file:

    mov ax, [di + 26]           ; 26 is offset to first cluster
    mov [stage2_cluster], ax

    ; load FAT
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    ; read file
    mov bx, STAGE2_LOAD_SEGMENT
    mov es, bx
    mov bx, STAGE2_LOAD_OFFSET
_load_file:
    ; first cluster = (stage2_cluster - 2) * sectors_per_cluster + start_sector
    ; start_sector = reserved_sectors + fat_count + rootdir_size
    mov ax, [stage2_cluster]
    add ax, 31          ; BAD
    
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read

    add bx, [bdb_bytes_per_sector]

    ; fat_index = current_cluster * 3 / 2
    mov ax, [stage2_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    mov si, buffer
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    jz _even
    ; if odd
    shr ax, 4
    jmp _cluster_after
_even:
    and ax, 0x0FFF

_cluster_after:
    cmp ax, 0x0FF8
    jae _load_file_end
    mov [stage2_cluster], ax
    jmp _load_file

_load_file_end:
    mov dl, [ebr_drive_number]      ; boot device
    mov ax, STAGE2_LOAD_SEGMENT     ; stage2 memory address
    mov ds, ax
    mov es, ax
    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

    jmp reboot_on_return
    jmp halt

;
; ERRORS AND ERROR HANDLING
;
halt:
    cli     ; disable interrupts
    hlt     ; halt system

reboot_on_return:
    mov ah, 0
    int 0x16
    cmp ah, 0x1c    ; check if enter
    jne reboot_on_return
    jmp 0x0FFFF:0   ; jump to start of bios

err_floppy:
    mov si, msg_floppy
    call puts
    jmp reboot_on_return

err_not_found:
    mov si, msg_not_found
    call puts
    jmp reboot_on_return

;
; PROCEDURES
;

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

; convert lba to chs
; INPUT:
;   ax - lba address
; OUTPUT:
;   cx[6:15]  - cylinder
;   dh        - head
;   cx[0:5]   - sector
chs:
    push ax
    push dx

    mov dx, 0
    div word [bdb_sectors_per_track]
    inc dx
    mov cx, dx

    mov dx, 0
    div word [bdb_heads]

    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax
    ret

; reset disk controller
; INPUT:
;   dl  - drive id
disk_reset:
    pusha               ; save registers
    mov ah, 0           ; setup INT 0x13 / AH=0x00
    stc                 ; set carry flag
    int 0x13            ; INT 0x13 / AH=0x00; 
    jc err_floppy     ; on failure jump to floppy error
    popa                ; retrieve registers
    ret

; read from disk
; INPUT:
;   ax      - lba address
;   cl      - sector count
;   dl      - disk id
;   es:bx   - destination
; COMMENT:
; floppy drives are unreliable
; so read ops should be retried multiple times
disk_read:
    push ax
    push bx
    push cx
    push dx
    push di   

    push cx
    call chs
    pop ax 

    mov ah, 0x02        ; setup INT 0x13 / AH=0x02
    mov di, 3           ; number of tries
_read_loop:
    pusha
    stc                 ; set carry flag
    int 0x13            ; clears carry flag on success
    jnc _read_loop_end  ; end if read was successful

    popa
    call disk_reset     ; fix broken disk handler

    ; count tries
    dec di
    cmp di, di
    jne _read_loop

    jmp err_floppy
_read_loop_end:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret


;
; DATA
;

msg_floppy:         db "Failed to read floppy", ENDL, 0
msg_not_found:      db "File STAGE2.BIN not found", ENDL, 0

file_stage2:            db "STAGE2  BIN"

stage2_cluster:         dw 0

STAGE2_LOAD_SEGMENT     equ 0x2000
STAGE2_LOAD_OFFSET      equ 0

;
; PADDING
;

times 510-($-$$) db 0
db 0x55, 0xaa

buffer: