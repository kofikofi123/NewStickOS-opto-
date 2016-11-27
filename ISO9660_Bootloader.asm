;Do not test anything below, please

org 0x7C00

jmp 0x00:Main

Reset_drive:
    mov ax, 0
    int 0x13 
    ret
    
Print_string: ;we are going to use the interrupt service because I do not need to directly write to it right now
    pusha
    pushf 
    cld
    
    mov ah, 0x0E
    mov bl, 0x0F
.looper:
    lodsb
    
    or al, al 
    jz .fini
    
    int 0x10 
    jmp .looper
.fini:
    popf
    popa 
    ret

Read_sector:;register destroyer
    mov cx, 3
    mov [disk_packet_struct.sectors_to_read], ax 
    mov word [disk_packet_struct.read_address], di
    mov word [disk_packet_struct.read_address + 2], bx 
    mov word [disk_packet_struct.lba_address], si 

.begin:
    mov dl, [bdrive]
    lea si, [disk_packet_struct] ;ds should already be 0
    mov ah, 0x42
    int 0x13
    jnc .fini
    loop .begin
.fini:
    ret
Read_file:
    ret  


Main:
    xor ax, ax 
    mov ds, ax
    
    cli
    mov ss, ax
    mov sp, 0x7DFF
    sti 
    
    mov [bdrive], dl
    ;Check if extended 0x13 funcctions are supported
    xchg bx, bx
    mov ah, 0x41
    mov bx, 0x55AA
    mov dl, [bdrive]
    int 0x13
    jnc .supported
    
    xchg bx, bx
    and cl, 1
    jnz .supported
.not_supported: ;
    lea si, [error_message2]
    call Print_string
    jmp looper
.supported: ; :(
    mov cl, 5
;reset drive
.reset_drive_begin:
    call Reset_drive 
    jnc .start_reading
    loop .reset_drive_begin
    lea si, [error_message1]
    call Print_string
    jmp looper
.start_reading:
    ;init data packet
    mov ax, 1 
    mov bx, 0 
    mov si, 0x10
    lea di, [disk_buffer]
    call Read_sector

looper:
    jmp looper

section .data
;variables
bdrive: db 0

error_message1: db "Unable to reset boot drive.", 0
error_message2: db "Extended bios interrupts not supported. Try again or use different bootloader", 0

test_message1: db "tester imager", 0
kernel_file_name db "STICK.BIN", 0 
boot_setting_file_name db ""

disk_packet_struct:
    db 0x10
    db 0 
.sectors_to_read:
    dw 0
.read_address:
    dw 0
    dw 0
.lba_address:
    dq 0

times 510-($-$$) db 0
db 0x55
db 0xAA
section .bss
disk_buffer: resb 2048