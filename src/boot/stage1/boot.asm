;
;   boot.asm
;
[org 0x7C00]                ; Add to the offsets
bits 16                     ; Emit 16-bit code

    jmp start

; -----------------------------------------------------------------------------
; FAT12 Headers
; -----------------------------------------------------------------------------
bdb_oem:                    db 'MSWIN4.1'           ; 8 Bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; 1.44 Megabytes from 2880 x 512
bdb_media_descriptor_type:  db 0F0h                 ; F0 is a 3.5" floppy disk
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

start:
    ; Setup data segments
    xor ax, ax              ; Set it to zero
    mov ds, ax              ; ds = 0
    mov es, ax

    ; Stack setup
    mov ss, ax              ; Stack starts at 0
    mov sp, 0x9C00

.after:
    cld                     ; Clear direction flag

    ; Prepare for reading
    mov [ebr_drive_number], dl

    ; Reset video mode (this clears the screen)
    mov ax, 0x03
    int 0x10
    mov ax, 0x9F20                  ; 0xBF20, B is background, F is foreground
    mov cx, 0x07D0
    push 0xB800
    pop es
    xor di, di
    rep stosw

    ; mov ax, 0xB800                  ; Text video memory
    ; mov es, ax

    ; mov si, msg_boot                ; Point to the message
    ; call sprint

    ; Read drive params (sectors per track & head count)
    push es,
    mov ah, 08h
    int 13h
    jc floppy_error
    pop es

    ;   Sectors
    and cl, 0x3F                    ; Trim top 2 bits
    xor ch, ch
    mov [bdb_sectors_per_track], cx ; Sector count

    ;   Heads
    inc dh
    mov [bdb_heads], dh             ; Head count

    ; Read FAT root directory
    mov ax, [bdb_sectors_per_fat]   ; lba of root = reserved + fats * sectors_per_fat
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx                          ; ax = fats * sectors_per_fat
    add ax, [bdb_reserved_sectors]  ; ax contains lba of root
    push ax

    mov ax, [bdb_dir_entries_count] ; Size of root directory = (32 * number_of_entries) / bytes_per_sector
    shl ax, 5                       ; ax *= 32
    xor dx, dx                      ; dx = 0
    div word [bdb_bytes_per_sector] ; Number of sectors to read

    test dx, dx                     ; If dx != 0, add 1
    jz .root_dir_after
    inc ax                          ; Division remainder != 0, add 1
                                    ; This means that a sector is only partially filled with entries

.root_dir_after:
    ; Read root directory
    mov cl, al                      ; Number of sectors to read = size of root directory
    pop ax                          ; lba of root directory
    mov dl, [ebr_drive_number]      ; Set dl to drive number
    mov bx, buffer                  ; es:bx = buffer
    call disk_read

    ; Search for stage2.bin
    xor bx, bx
    mov di, buffer

.search_stage2:
    mov si, file_stage2             ; Store the stage2.bin file in the si register
    mov cx, 11                      ; Compare up to 11 characters
    push di
    repe cmpsb                      ; repe repeats a string instruction until cx reaches 0
                                    ; cmpsb compares two bytes located at ds:si and es:di

    pop di
    je .found_stage2                ; We found the stage2!

    add di, 32                      ; Move to the next directory entry
    inc bx
    cmp bx, [bdb_dir_entries_count] ; Check if there are entries left
    jl .search_stage2               ; If there are, restart this loop

    jmp msg_stage2_fail             ; stage2 couldn't be found

.found_stage2:
    ; di should have he address to the entry
    mov ax, [di + 26]               ; First logical cluster field has offset 26
    mov [stage2_cluster], ax

    ; Load FAT from disk into memory
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    ; Read stage2 and process FAT chain
    mov bx, STAGE2_LOAD_SEGMENT
    mov es, bx
    mov bx, STAGE2_LOAD_OFFSET

.load_stage2_loop:
    ; Read next cluster
    mov ax, [stage2_cluster]

    add ax, 31                      ; First cluster = (cluster number - 2) * sectors_per_cluster + start_sector
                                    ; Start sector = reserved + fats + root directory size

    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read
    
    add bx, [bdb_bytes_per_sector]  ; Will overflow if the stage2.bin file is larger than 64 kb

    ; Get location of the next cluster
    mov ax, [stage2_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx                          ; ax = index of entry in FAT, dx = cluster % 2

    mov si, buffer
    add si, ax
    mov ax, [ds:si]                 ; Read entry from FAT table at index

    or dx, dx
    jz .even

.odd:
    shr ax, 4
    jmp .next_cluster_after

.even:
    and ax, 0x0FFF

.next_cluster_after:
    cmp ax, 0x0FF8                  ; End of the file data chain
    jae .read_finish

    mov [stage2_cluster], ax
    jmp .load_stage2_loop

.read_finish:
    ; Jump to the stage2
    mov dl, [ebr_drive_number]      ; Boot device into dl
    mov ax, STAGE2_LOAD_SEGMENT     ; Set segment registers

    mov ds, ax
    mov es, ax
    
    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

    jmp wait_key_and_reboot         ; Should NEVER run

; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------

.wrapup:
    ; mov ax, 0xB800                  ; Look at video memory
    ; mov gs, ax
    ; mov bx, 0x0000
    ; mov ax, [gs:bx]

    ; Do prints
    ; mov word [reg16], ax            ; Look at register
    ; call printreg16

    cli                             ; Disable interrupts
    hlt                             ; Stop executing on CPU

; ----------------------------------------------------------------------------- 
;   Printing functions
; -----------------------------------------------------------------------------
; dochar: call cprint

; ;
; ;   Print string
; ;
; sprint: lodsb                       ; Load from si into al, ax or eax (in this case, al)
;     cmp al, 0
;     jne dochar                      ; Jump to dochar is zf is clear

;     add byte [ypos], 1              ; Down a row
;     add byte [xpos], 0              ; Reset to the left-most column 

;     ret

; ;
; ;   Print single character
; ;
; cprint:
;     mov ah, 0x9F                    ; 0xBF, B is background, F is foreground (see COLORS.md for a table of colors)
;     mov cx, ax                      ; Save character/attribute
;     movzx ax, byte [ypos]           ; Move into ax with zero-extending

;     mov dx, 160                     ; 2 bytes
;     mul dx                          ; Turns into 80 columns

;     movzx bx, byte [xpos]           ; Zero-extend xpos as well
;     shl bx, 1                       ; Shift bx 1 bit to the left

;     mov di, 0                       ; Start of video memory
;     add di, ax                      ; Add y offset
;     add di, bx                      ; Add x offset

;     mov ax, cx                      ; Restore character/attribute
;     stosw                           ; Store word from ax
;     add byte [xpos], 1              ; Advance to the right

;     ret

; printreg16:
;     mov di, outstr16
;     mov ax, [reg16]
;     mov si, hexstr
;     mov cx, 4                       ; Four places

; hexloop:
;     ; Turn left-most into right-most
;     rol ax, 4
;     mov bx, ax
;     and bx, 0x0F

;     mov bl, [si + bx]               ; Index to hexstr
;     mov [di], bl
;     inc di
;     dec cx

;     jmp hexloop

;     mov si, outstr16
;     call sprint

;     ret

; ----------------------------------------------------------------------------- 
;   Error Handlers
; -----------------------------------------------------------------------------
floppy_error:
    ; mov si, msg_read_fail
    ; call sprint

    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                         ; Wait for keypress

    jmp 0FFFFh:0                    ; Jump to the beginning of the BIOS,
                                    ; effectively rebooting the system.

.halt:
    cli                             ; Disable interrupts
    hlt                             ; Stop executing on CPU

; ----------------------------------------------------------------------------- 
;   Disk Routines
; -----------------------------------------------------------------------------
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

    push cx                             ; Save cl to the stack
    call lba_to_chs                     ; Convert the address
    pop ax                              ; al is the number of sectors to read
    
    mov ah, 02h
    mov di, 3                           ; Retry count (floppy unreliability has the documentation recommend to retry reading three times)

.retry:
    pusha                               ; Save all registers, since we don't know what the bios modifies
    stc                                 ; Set the carry flag, since some BIOS don't set it
    int 13h                             ; If the carry flag cleared, we can jump out of the loop
    jnc .done                           ; Jump if the carry is not set
    
    ; Execute when a read fails
    popa
    call disk_reset
    
    dec di
    test di, di                         ; Check if di is zero
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

; -----------------------------------------------------------------------------
;   Variables
; -----------------------------------------------------------------------------
xpos                db 0
ypos                db 0
hexstr              db '0123456789ABCDEF'
outstr16            db '0000', 0    ; Register value string
reg16               dw 0            ; Pass values to printreg16

msg_boot            db 'Booting', 0
msg_read_fail       db 'Failed to boot', 0
msg_stage2_fail     db 'Failed STAGE 2', 0

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
dw 0AA55h                           ; Some BIOSes require this to identify the bootsector

buffer: