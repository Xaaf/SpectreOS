;
;   main.asm
;
bits 16                     ; Emit 16-bit code
section _ENTRY class=CODE

extern _cstart_
global entry

entry:
    ; Disable interrupts whilst setting the stack up
    cli

    mov ax, ds
    mov ss, ax
    mov sp, 0
    mov bp, sp

    sti

    ; Boot drive expected in dl, send it to cstart
    xor dh, dh
    push dx
    call _cstart_

    ; Halt if we return from cstart
    cli
    hlt