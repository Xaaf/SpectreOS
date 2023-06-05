;
;   x86.asm
;

bits 16

section _TEXT class=CODE

;
; void _cdecl x86_div64_32(uint64_t dividend, uint32_t divisor, uint64_t* quotientOut, uint32_t* remainderOut);
;
global _x86_div64_32                                ; Will be called from C
_x86_div64_32:
    ; Make new call frame
    push bp                                         ; Save the old call frame
    mov bp, sp                                      ; Initialise the new call frame

    push bx

    ; Divide upper 32 bits
    mov eax, [bp + 8]                               ; Move the upper 32 bits into eax
    mov ecx, [bp + 12]                              ; Move the divisor into ecx
    xor edx, edx                                    ; Clear edx
    div ecx                                         ; eax contains quotient
                                                    ; edx contains remainder

    ; Store the upper 32 bits of the quotient
    mov bx, [bp + 16]
    mov [bx + 4], eax

    ; Divide lower 32 bits
    mov eax, [bp + 4]                               ; Move the lower 32 bits into eax
                                                    ; edx already contains the remainder
    div ecx

    ; Store the result
    mov [bx], eax
    mov bx, [bp + 18]
    mov [bx], edx

    pop bx

    ; Restore the old call frame
    mov sp, bp
    pop bp
    ret

;
; void _cdecl x86_Video_WriteCharTeletype(char c, uint8_t page);
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
