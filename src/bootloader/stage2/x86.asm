;
;   x86.asm
;

bits 16

section _TEXT class=CODE

;
; int 10h ah=0Eh
; Params:
;       character
;       page
;
global _x86_Video_WriteCharTeletype                  ; Will be called from C
_x86_Video_WriteCharTeletype:
    ; Make new call frame
    push bp                                         ; Save the old call frame
    mov bp, sp                                      ; Initialise the new call frame

    ; Save bx
    push bx

    ; [bp + 0]: Old call frame
    ; [bp + 2]: Return address (small memory model --> 2 bytes)
    ; [bp + 4]: character argument
    ; [bp + 6]: page argument
    ;   --> Bytes are converted to words, since you can't push a single byte onto the stack
    mov ah, 0Eh
    mov al, [bp + 4]
    mov bh, [bp + 6]

    int 10h

    ; Restore bx
    pop bx

    ; Restore the old call frame
    mov sp, bp
    pop bp
    ret
