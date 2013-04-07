;first version of TSR
;maybe it fails, it's not tested properly

SECTION .text
    org 0x100

; go to useful code
_entry_point:
    jmp _main

;TSR data
prev_handler dd 0 ;?

;TSR code
_resident:
    
    cmp ah, 0deh ;resident ID
    jne _int2fh_pass

    cmp al, 00h
    je _int2fh_present

    cmp al, 01h
    je _int2fh_remove

    ;should be an iret here?
    iret

_int2fh_pass:
    jmp [cs:prev_handler]
    
_int2fh_present:
    mov al, 0ffh ;we are here
    iret

_int2fh_remove:
    push ds
    push es
    push dx

    mov ax, 252fh
    ;ds:dx
    mov ds, [cs:prev_handler+2]
    mov dx, [cs:prev_handler]
    int 21h

    ;;kill env
    ;mov es, [cs:2ch] 
    ;mov ah, 49h 
    ;int 21h

    ;kill self
    push cs
    pop es 
    mov ah, 49h
    int 21h

    pop dx
    pop es
    pop ds
    iret  

_size dw $ - _resident ;?

_main:
    ;CMD args parser
    mov cx, [es:0x80]
    xor ch, ch
    mov dx, cx
    

    mov si, 0x82 ; ignore 81's space

    _read_loop:
        lodsb ;load cmd arg to al
        lea bx, [_map]
        xlat ;get table column from map

        mov dx, ax

        lea bx, [_table]
        push ax
        mov dx, 8
        xor ax, ax
        mov al, [_state]
        mul dx
        add bx, ax
        pop ax
        xlat
        mov [_state], al
        dec cx ;cmd length -1
        cmp cx, 1
        jg _read_loop

        cmp al, 1 ; '-' or '/' specified at cmdline
        je __help

        cmp al, 2
        je __help
        cmp al, 3
        je __install
        cmp al, 4
        je __state
        cmp al, 5
        je __uninstall

        ;wtf situation!
        jmp _sysexit



__help: ;obvious
    mov ah, 0x9
    mov dx, _help_msg
    int 0x21

    jmp _sysexit

__install: ;set TSR
    call _check_tsr
    je _is_loaded
    ;replace interrupt handler

    push dx
    push ds
    mov ax, 352fh ;35 = get interrupt vector,
    ;for 2F (multiplex)
    ;results: ES:BX - current handler
    int 21h
    mov word [prev_handler], bx ;?
    mov word [prev_handler+2], es ;?
    mov ax, 252fh ;25 = set interrupt vector
    mov dx, _resident
    ;for 2F
    ;results: DS:DX - new handler
    int 21h
    pop ds
    pop dx
    
    mov ah, 0x9
    mov dx, _install_msg
    int 0x21
    
    ;kill env
    mov es, [cs:2ch] 
    mov ah, 49h 
    int 21h

    mov ah, 48h
    mov bx, 0x1
    mov [cs:2ch], ax
    


    

    ;now Terminate And Stay Resident:
    ;calculate size of TSR part in paragraphs
    mov dx, (_size - _entry_point + 10h) / 10h + 10h
    ;mov dx, 0x6
    mov ax, dx
    call _dump_word
    mov ax, 3100h
    int 21h

    jmp _sysexit
    


__state: ;check if TSR loaded
    mov ah, 0x9
    mov dx, _state_msg
    int 0x21
    call _check_tsr
    je _is_loaded
    jne _not_loaded
    jmp _sysexit

__uninstall: ;unload TSR
    call _check_tsr
    jne _not_loaded



    push dx
    push ds
    mov ax, 352fh ;35 = get interrupt vector,
    int 21h
    mov word [prev_handler], bx ;?
    mov word [prev_handler+2], es ;?
    pop ds
    pop dx

    mov ah, 0deh
    mov al, 01h ;resident ID, 01 - uninstall request
    int 2fh ;multiplex interrupt

    mov ah, 0x9
    mov dx, _uninstall_msg
    int 0x21
    jmp _sysexit

    ;jmp _sysexit

_dump_word: ;dump AX
    xchg al, ah
    call _dump_byte
    xchg al, ah
    call _dump_byte
    ret

_dump_byte: ;dump AL  
    push bx
    push cx
    push dx
    push ax
    push ax ;yes, second time!

    lea bx, [_hex]
    shr al, 4
    xlat
    mov dl, al
    mov ah, 2
    int 21h
    pop ax ;look here!
    and al, 0x0F
    xlat
    mov dl, al
    mov ah, 2
    int 21h

    pop ax
    pop dx
    pop cx
    pop bx
    ret

_sysexit:
    mov ax, 0x4de0
    int 0x21
    ret

_check_tsr: ;check if TSR already loaded ;? what is the return?
    mov ax, 0de00h ;resident ID, 00 - installation check
    int 2fh ;multiplex interrupt
    cmp al, 0ffh ; answer signature
    ret

_is_loaded: ;TSR already loaded
    mov ah, 0x9
    mov dx, _is_loaded_msg
    int 0x21

    jmp _sysexit

_not_loaded: ;TSR isn't loaded
    mov ah, 0x9
    mov dx, _not_loaded_msg
    int 0x21
    jmp _sysexit
    

SECTION .data
        _name db 'anonymous'
        _hello db "Hello"
        _state db 0
        _newline db 13,10,'$'
        _hex db "0123456789ABCDEF"
        _tmp_print_str db "0$"
        _test db "test!",13,10,'$'
        _nothing db "Greetings!",13,10,"Nothing happened, dude.",13,10,'$'
        _help_msg db "Usage: -h(elp) -i(nstall) -s(tate) -u(ninstall)",13,10,'$'
        _install_msg db "Installed.",13,10,'$'
        _state_msg db "State: ",'$'
        _uninstall_msg db "Uninstalled.",13,10,'$'
        _is_loaded_msg db "TSR already loaded.",13,10,'$'
        _not_loaded_msg db "TSR is not loaded.",13,10,'$'

        ;automata
        ;      0 1 2 3 4 5 6 7
        ;      / - h i s u _ *
  _table    db 1,1,2,2,2,2,0,2 ;0
            db 2,2,2,3,4,5,6,2 ;1
            db 2,2,2,2,2,2,2,2 ;2 - help
            db 2,2,2,3,2,2,2,2 ;3 - install
            db 2,2,2,2,4,2,2,2 ;4 - state
            db 2,2,2,2,2,5,2,2 ;5 - uninstall
            db 2,2,2,2,2,2,2,2 ;6 = fail
        
        ;ASCII-map
        ;   [space] 32
        ;   -       45
        ;   /       47
        ;   h       104
        ;   i       105
        ;   s       115
        ;   u       117
        ;   [all]   ?

        
    _map    times 32 db 7       ;all (0..31)
            db 6                ; [space] (offset 32)
            times 12 db 7       ;all (33..44)
            db 1                ; - (45)
            db 7                ;all
            db 0                ; / (47)
            times 56 db 7       ;all (48..103)
            db 2                ; h (104)
            db 3                ; i (105)
            times 9 db 7        ;all (106..114)
            db 4                ; s (115)
            db 7                ;all (116)
            db 5                ; u (117)



SECTION .bss
        tmp_str resb 3
        tmp resw 1