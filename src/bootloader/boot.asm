;
;   boot.asm
;

org 0x7C00                              ; Use this offset
bits 16                                 ; Start in 16-bit mode (emitting 16-bit code)

%define ENDL 0x0D, 0x0A

;
; FAT12 Header
;
jmp short start
nop

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

;
; Bootloader
;
start:
    ; Set up data segments
    mov ax, 0                           ; Can't write to ds/es directly
    mov ds, ax
    mov es, ax

    ; Set up the stack
    mov ss, ax
    mov sp, 0x7C00                      ; Stack goes down from where we load in memory (preventing overwriting our program)

    ; Some BIOS have a different start, so make sure we are in the expected memory location
    push es
    push word .after
    retf

.after:
    ; Read something from the floppy
    ; BIOS should set dl to drive number
    mov [ebr_drive_number], dl

    mov ax, 1                           ; LBA = 1, second sector from the disk
    mov cl, 1                           ; 1 sector to read
    mov bx, 0x7E00                      ; Data should be stored after the bootloader
    call disk_read

    ; Print loading message
    mov si, msg_loading                 ; Set si to msg_loading
    call puts                           ; Call the method for printing a string

    ; Read drive parameters (sectors per track and head count), instead of 
    ; relying on data on the formatted disk
    push es
    mov ah, 08h
    int 13h
    jc floppy_error
    pop es

    and cl, 0x3F                        ; Remove top 2 bits
    xor ch, ch
    mov [bdb_sectors_per_track], cx     ; Sector count

    inc dh
    mov [bdb_heads], dh                 ; Head count

    ; Read FAT root directory
    mov ax, [bdb_sectors_per_fat]       ; lba of root directory = reserved + fats * sectors_per_fat
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx                              ; ax = (fats * sectors_per_fat)
    add ax, [bdb_reserved_sectors]      ; ax = lba of root directory
    push ax

    mov ax, [bdb_dir_entries_count]     ; Size of root directory = (32 * number_of_entries) / bytes_per_sector
    shl ax, 5                           ; ax *= 32
    xor dx, dx                          ; dx = 0
    div word [bdb_bytes_per_sector]     ; Number of sectors to read

    test dx, dx                         ; If dx != 0, add 1
    jz .root_dir_after
    inc ax                              ; Division remainder != 0, add 1
                                        ; This means that a sector is only partially filled with entries

.root_dir_after:
    ; Read root directory
    mov cl, al                          ; Number of sectors to read = size of root directory
    pop ax                              ; lba of root directory
    mov dl, [ebr_drive_number]          ; Set dl to drive number
    mov bx, buffer                      ; es:bx = buffer
    call disk_read

    ; Search for kernel.bin
    xor bx, bx
    mov di, buffer

.search_kernel:
    mov si, file_kernel_bin             ; Store the kernel.bin file in the si register
    mov cx, 11                          ; Compare up to 11 characters
    push di
    repe cmpsb                          ; repe repeats a string instruction until cx reaches 0
                                        ; cmpsb compares two bytes located at ds:si and es:di

    pop di
    je .found_kernel                    ; We found the kernel!

    add di, 32                          ; Move to the next directory entry
    inc bx
    cmp bx, [bdb_dir_entries_count]     ; Check if there are entries left
    jl .search_kernel                   ; If there are, restart this loop

    jmp kernel_not_found_error          ; Kernel couldn't be found

.found_kernel:
    ; di should have he address to the entry
    mov ax, [di + 26]                   ; First logical cluster field has offset 26
    mov [kernel_cluster], ax

    ; Load FAT from disk into memory
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    ; Read kernel and process FAT chain
    mov bx, KERNEL_LOAD_SEGMENT
    mov es, bx
    mov bx, KERNEL_LOAD_OFFSET

.load_kernel_loop:
    ; Read next cluster
    mov ax, [kernel_cluster]

    add ax, 31                          ; First cluster = (cluster number - 2) * sectors_per_cluster + start_sector
                                        ; Start sector = reserved + fats + root directory size

    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read
    
    add bx, [bdb_bytes_per_sector]      ; Will overflow if the kernel.bin file is larger than 64 kb

    ; Get location of the next cluster
    mov ax, [kernel_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx                              ; ax = index of entry in FAT, dx = cluster % 2

    mov si, buffer
    add si, ax
    mov ax, [ds:si]                     ; Read entry from FAT table at index

    or dx, dx
    jz .even

.odd:
    shr ax, 4
    jmp .next_cluster_after

.even:
    and ax, 0x0FFF

.next_cluster_after:
    cmp ax, 0x0FF8                      ; End of the file data chain
    jae .read_finish

    mov [kernel_cluster], ax
    jmp .load_kernel_loop

.read_finish:
    ; Jump to the kernel
    mov dl, [ebr_drive_number]          ; Boot device into dl
    mov ax, KERNEL_LOAD_SEGMENT         ; Set segment registers
    mov ds, ax
    mov es, ax

    jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET

    jmp wait_key_and_reboot             ; This should never run

    cli                                 ; Disable interrupts, locking the CPU in "halt" state
    hlt                                 ; Stop CPU from executing

;
; Error Handlers
;

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

kernel_not_found_error:
    mov si, msg_kernel_not_found
    call puts
    jmp wait_key_and_reboot


wait_key_and_reboot:
    mov ah, 0
    int 16h                             ; Wait for keypress

    jmp 0FFFFh:0                        ; Jump to beginning of BIOS, effectively rebooting

.halt:
    cli                                 ; Disable interrupts, locking the CPU in "halt" state
    hlt                                 ; Stop CPU from executing

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

msg_loading:            db 'Loading...', ENDL, 0
msg_read_failed:        db 'Failed to read from disk!', ENDL, 0
msg_kernel_not_found:   db 'KERNEL.BIN file not found!', ENDL, 0
file_kernel_bin:        db 'KERNEL  BIN'    ; Padded with spaces to get 11 characters
kernel_cluster:         dw 0

KERNEL_LOAD_SEGMENT     equ 0x2000
KERNEL_LOAD_OFFSET      equ 0

times 510-($-$$) db 0                   ; $ is the memory offset of the current line,
                                        ; $$ is the memory offset of the beginning of the current section

dw 0AA55h                               ; Write 2 byte value

buffer: