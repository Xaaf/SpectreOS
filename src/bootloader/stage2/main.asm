;
;   main.asm
;

bits 16
section _ENTRY class=CODE

extern _cstart_
global entry

entry:
    ; Disable interrupts while setting up the stack
    cli

    mov ax, ds
    mov ss, ax
    mov sp, 0
    mov bp, sp

    sti

    ; Boot drive is expected in dl, send it to cstart function
    xor dh, dh
    push dx
    call _cstart_

    ; Halt the system if we, for any reason, return from the cstart function
    cli
    hlt