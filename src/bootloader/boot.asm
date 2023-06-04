;
;   boot.asm
;

org 0x7C00              ; Use this offset
bits 16                 ; Start in 16-bit mode (emitting 16-bit code)

%define ENDL 0x0D, 0x0A

;
; FAT12 Header
;
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'       ; 8 Bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880             ; 1.44 Megabytes from 2880 x 512
bdb_media_descriptor_type:  db 0F0h             ; F0 is a 3.5" floppy disk
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; Extended boot record
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd, useless
                            db 0                    ; Reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; Serial number, value doesn't matter
ebr_volume_label:           db 'SPECTRE OS '        ; 11 bytes
ebr_system_id:              db 'FAT12   '           ; 8 bytes

;
; Bootloader
;
start:
    jmp main            ; Make sure the prgram starts at the main section

;
; Print a string to the screen.
; Params:
;       ds:si String to print
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

    ; Read something from the floppy
    ; BIOS should set dl to drive number
    mov [ebr_drive_number], dl

    mov ax, 1           ; LBA = 1, second sector from the disk
    mov cl, 1           ; 1 sector to read
    mov bx, 0x7E00      ; Data should be stored after the bootloader
    call disk_read

    ; Print 'Hello world!'
    mov si, msg_hello   ; Set si to msg_hello
    call puts           ; Call the method for printing a string

    cli                 ; Disable interrupts, locking the CPU in "halt" state
    hlt                 ; Stop CPU from executing

;
; Error Handlers
;

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                             ; Wait for keypress

    jmp 0FFFFh:0                        ; Jump to beginning of BIOS, effectively rebooting

.halt:
    cli                                 ; Disable interrupts, locking the CPU in "halt" state
    hlt

;
; Disk routines
;

;
; Convert an LBA address to a CHS address
; Params:
;       ax LBA Address
; Return:
;       cx [bits 0-5] Sector number
;       cx [bits 6-15] Cylinder
;       dh Head
;
lba_to_chs:
    push ax
    push dx

    xor dx, dx                          ; dx = 0
    div word [bdb_sectors_per_track]    ; ax = LBA / SectorsPerTrack
                                        ; dx = LBA % SectorsPerTrack

    inc dx                              ; dx = (LBA % SectorsPerTrack + 1), which is the sector
    mov cx, dx                          ; Store this sector in cx

    xor dx, dx                          ; dx = 0
    div word [bdb_heads]                ; ax = (LBA / SectorsPerTrack) / Heads, which is the cylinder
                                        ; dx = (LBA / SectorsPerTrack) % Heads, which is the head

    mov dh, dl                          ; dh is now the head
    mov ch, al                          ; ch is the cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                           ; Put the upper 2 bits of the cylinder into cl

    pop ax
    mov dl, al                          ; Restore dl
    pop ax

    ret

;
; Reads sectors from a disk.
; Params:
;       ax LBA Address
;       cl Number of sectors to read (up to 128)
;       dl Drive number
;       es:bx Memory address where the read data will be stored
;
disk_read:
    ; Save registers that will be modified
    push ax
    push bx
    push cx
    push dx
    push di

    push cx             ; Save cl to the stack
    call lba_to_chs     ; Convert the address
    pop ax              ; al is the number of sectors to read
    
    mov ah, 02h
    mov di, 3           ; Retry count (floppy unreliability has the documentation recommend to retry reading three times)

.retry:
    pusha               ; Save all registers, since we don't know what the bios modifies
    stc                 ; Set the carry flag, since some BIOS don't set it
    int 13h             ; If the carry flag cleared, we can jump out of the loop
    jnc .done           ; Jump if the carry is not set
    
    ; Execute when a read fails
    popa
    call disk_reset
    
    dec di
    test di, di         ; Check if di is zero
    jnz .retry

.fail:
    ; All three attempts failed
    jmp floppy_error

.done:
    popa

    ; Restore modified registers
    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret

;
; Reset disk controller.
; Params:
;       dl Drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa

    ret

msg_hello:          db 'Hello world!', ENDL, 0
msg_read_failed:    db 'Failed to read from disk!', ENDL, 0

times 510-($-$$) db 0   ; $ is the memory offset of the current line,
                        ; $$ is the memory offset of the beginning of the current section

dw 0AA55h               ; Write 2 byte value