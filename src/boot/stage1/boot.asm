;
;   boot.asm
;
[org 0x7C00]                ; Add to the offsets
bits 16                     ; Emit 16-bit code

    jmp start
    nop                     ; Skip to next instruction

start:
    xor ax, ax              ; Set it to zero
    mov ds, ax              ; ds = 0
    mov ss, ax              ; Stack starts at 0
    mov sp, 0x9C00

    cld                     ; Clear direction flag

    ; Reset video mode (this clears the screen)
    mov ax, 0x03
    int 0x10
    mov ax, 0x9F20          ; 0xBF20, B is background, F is foreground
    mov cx, 0x07D0
    push 0xB800
    pop es
    xor di, di
    rep stosw

    mov ax, 0xB800          ; Text video memory
    mov es, ax

    mov si, msg_boot             ; Point to the message
    call sprint

    mov ax, 0xB800          ; Look at video memory
    mov gs, ax
    mov bx, 0x0000
    mov ax, [gs:bx]

    mov word [reg16], ax    ; Look at register
    call printreg16

hang:
    jmp hang

; ----------------------------------------------------------------------------- 
;   Printing functions
; -----------------------------------------------------------------------------
dochar: call cprint

;
;   Print string
;
sprint: lodsb               ; Load from si into al, ax or eax (in this case, al)
    cmp al, 0
    jne dochar              ; Jump to dochar is zf is clear

    add byte [ypos], 1      ; Down a row
    add byte [xpos], 0      ; Reset to the left-most column 

    ret

;
;   Print single character
;
cprint: mov ah, 0x9F        ; 0xBF, B is background, F is foreground (see COLORS.md for a table of colors)
    mov cx, ax              ; Save character/attribute
    movzx ax, byte [ypos]   ; Move into ax with zero-extending

    mov dx, 160             ; 2 bytes
    mul dx                  ; Turns into 80 columns

    movzx bx, byte [xpos]   ; Zero-extend xpos as well
    shl bx, 1               ; Shift bx 1 bit to the left

    mov di, 0               ; Start of video memory
    add di, ax              ; Add y offset
    add di, bx              ; Add x offset

    mov ax, cx              ; Restore character/attribute
    stosw                   ; Store word from ax
    add byte [xpos], 1      ; Advance to the right

    ret

printreg16:
    mov di, outstr16
    mov ax, [reg16]
    mov si, hexstr
    mov cx, 4               ; Four places

hexloop:
    ; Turn left-most into right-most
    rol ax, 4
    mov bx, ax
    and bx, 0x0F

    mov bl, [si + bx]       ; Index to hexstr
    mov [di], bl
    inc di
    dec cx

    jmp hexloop

    mov si, outstr16
    call sprint

    ret

; -----------------------------------------------------------------------------
;   Variables
; -----------------------------------------------------------------------------
xpos                db 0
ypos                db 0
hexstr              db '0123456789ABCDEF'
outstr16            db '0000', 0    ; Register value string
reg16               dw 0            ; Pass values to printreg16

msg_boot            db 'Booting up SpectreOS...', 0
msg_read_fail       db 'Failed to boot SpectreOS.', 0
msg_stage2_fail     db 'STAGE2.BIN file not found!', 0

; Files should be padded to 11 characters
file_stage2         db 'STAGE2  BIN'

; Stage 2 values
stage2_cluster      dw 0

STAGE2_LOAD_SEGMENT equ 0x2000
STAGE2_LOAD_OFFSET  equ 0

;
;   Padding the bootsector
;
times 510-($-$$) db 0
db 0xAA55                   ; Some BIOSes require this to identify the bootsector

buffer: