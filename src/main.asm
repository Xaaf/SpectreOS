org 0x7C00              ; Use this offset
bits 16                 ; Start in 16-bit mode (emitting 16-bit code)

%define ENDL 0x0D, 0x0A

start:
    jmp main            ; Make sure the prgram starts at the main section

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
    lodsb               ; Load the next character in al

    or al, al           ; Bitwise operation between source and destination,
                        ; storing the result in destination. Verifies if the
                        ; next character is null

    jz .done            ; Jump to the destination (in this case the .done label)
                        ; if the zero flag is set

    mov ah, 0x0E        ; Call bios interrupt
    mov bh, 0
    int 0x10

    jmp .loop

.done:
    ; Clean up and return
    pop bx
    pop ax
    pop si

    ret

main:
    ; Set up data segments
    mov ax, 0           ; Can't write to ds/es directly
    mov ds, ax
    mov es, ax

    ; Set up the stack
    mov ss, ax
    mov sp, 0x7C00      ; Stack goes down from where we load in memory (preventing overwriting our program)

    ; Print 'Hello world!'
    mov si, msg_hello   ; Set si to msg_hello
    call puts           ; Call the method for printing a string

    hlt                 ; Stop CPU from executing

.halt:
    jmp .halt

msg_hello: db 'Hello world!', ENDL, 0

times 510-($-$$) db 0   ; $ is the memory offset of the current line,
                        ; $$ is the memory offset of the beginning of the current section

dw 0AA55h               ; Write 2 byte value