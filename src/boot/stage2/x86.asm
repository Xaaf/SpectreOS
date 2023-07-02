;
;   x86.asm
;
bits 16

section _TEXT class=CODE

;
; void _cdecl x86_div64_32(uint64_t dividend, uint32_t divisor, uint64_t* qoutient_out, uint32_t* remainder_out);
;
global _x86_div64_32                    ; To be called from C
_x86_div64_32:
    ; Make new call frame
    push bp                             ; Save old call frame
    mov bp, sp                          ; Initialise new call frame

    push bx                             ; Save bx

    ; Divide upper 32 bits
    mov eax, [bp + 8]                   ; Move upper 32 bits into eax
    mov ecx, [bp + 12]                  ; Move divisor into ecx
    xor edx, edx                        ; Clear edx for usage
    div ecx                             ; eax contains the quotient
                                        ; edx contains the remainder

    ; Store upper 32 bits of the quotient
    mov bx, [bp + 16]
    mov [bx + 4], eax

    ; Divide lower 32 bits
    mov eax, [bp + 4]                   ; Move lower 32 bits into eax
                                        ; edx contains the remainder
    div ecx

    ; Store the result
    mov [bx], eax
    mov bx, [bp + 18]
    mov [bx], edx

    pop bx                              ; Restore bx

    ; Restore old call frame
    mov sp, bp
    pop bp
    ret

; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
;
; void _cdecl x86_write_char_teletype(char c, uint8_t page);
;
global _x86_write_char_teletype         ; To be called from C
_x86_write_char_teletype:
    ; Make new call frame
    push bp                             ; Save old call frame
    mov bp, sp                          ; Initialise new call frame

    push bx                             ; Save bx

    ; [bp + 0]: Old call frame
    ; [bp + 2]: Return address (small memory model --> 2 bytes)
    ; [bp + 4]: character argument
    ; [bp + 6]: page argument
    ;   --> Bytes are converted to words, since you can't push a single byte onto the stack
    mov ah, 0Eh
    mov al, [bp + 4]
    mov bh, [bp + 6]
    
    int 10h

    pop bx                              ; Restore bx

    ; Restore old call frame
    mov sp, bp
    pop bp
    ret
