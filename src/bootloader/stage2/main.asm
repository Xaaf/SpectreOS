;
;   main.asm
;

org 0x7C00                              ; Use this offset
bits 16                                 ; Start in 16-bit mode (emitting 16-bit code)

%define ENDL 0x0D, 0x0A

main:
    ; Print 'Hello from Stage 2!'
    mov si, msg_hello                   ; Set si to msg_hello
    call puts                           ; Call the method for printing a string

.halt:
    cli                                 ; Disable interrupts, locking the CPU in "halt" state
    hlt                                 ; Stop CPU from executing

;
; Print a string to the screen.
; Params:
;       ds:si points to a string
;
puts:
    ; Save the registers that will be modified
    push si
    push ax
    push bx

.loop:
    lodsb                               ; Load the next character in al

    or al, al                           ; Bitwise operation between source and destination,
                                        ; storing the result in destination. Verifies if the
                                        ; next character is null

    jz .done                            ; Jump to the destination (in this case the .done label)
                                        ; if the zero flag is set

    mov ah, 0x0E                        ; Call bios interrupt
    mov bh, 0
    int 0x10

    jmp .loop

.done:
    ; Clean up and return
    pop bx
    pop ax
    pop si

    ret

msg_hello: db 'Hello from Stage 2!', ENDL, 0
