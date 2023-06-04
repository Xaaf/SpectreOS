org 0x7C00              ; Use this offset
bits 16                 ; Start in 16-bit mode (emitting 16-bit code)

main:
    hlt                 ; Stop CPU from executing

.halt:
    jmp .halt

times 510-($-$$) db 0   ; $ is the memory offset of the current line, $$ is the memory offset of the beginning of the current section
dw 0AA55h               ; Write 2 byte value