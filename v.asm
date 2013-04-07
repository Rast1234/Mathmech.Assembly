;displays ASCII table
;works in different video modes

SECTION .text
	org 0x100

_main:

    mov di, 0xB800
    
    ;video modes
        mov ax, 0x0F00
        int 0x10
        cmp al, 0x07
        jne _ok
        sub di, 0x0800
        _ok:
    ;   set display page offset

    ;resolutions
        cmp ah, 40d
        jne _big

        mov word [start], 0xA4
        mov word [newline], 0x2*2+0x3*2
        mov word [bottom], 0xA4 + 0x50*19d
        mov byte [length], 0x50
        mov word [pagesize], 0x0080

    _big:
    mov cl, bh
    xor ch, ch
    mov ax, [es:pagesize]
    _pages:
    add di, ax
    loop _pages

    push di
    push ds
    pop es
    pop ds ;load video segment to ds


    mov bx, [es:start]
        ;HIGH: color
        ; LOW: letter
    mov dh, 0x02; 0b00000010
;;;;;;;;;;;;;;;;;drawing;;;;;;;;;;;;;;;;;;;;;;;;
    
    ;corners
    push bx
    mov [bx], byte 0xC9 ;left top
    mov [bx+1], byte 0x02
    mov al, byte [es:length]
    xor ah, ah
    add bx, ax
    mov [bx], word 0x02BA
    add bx, ax
    mov [bx], word 0x02BA
    pop bx

    mov [bx+0x22*2], byte 0xBB ;right top
    mov [bx+0x22*2+1], byte 0x02

    push bx
    mov bx, [es:bottom]

    mov [bx], byte 0xC8 ;left bottom
    mov [bx+1], byte 0x02

    mov [bx+0x22*2], byte 0xBC ;right bottom
    mov [bx+0x22*2+1], byte 0x02
    pop bx
    
    ;horizontal lines
    mov dl, 0xCD ;horizontal bold
    add bx, 2 ;after corner
    push bx
    push bx
    push bx
    call _line
    pop bx
    mov ah, [es:length]
    mov al, 19d
    mul ah
    add bx, ax
    call _line
    pop bx
    mov dl, 0xC4 ;horizontal thin
    mov ah, [es:length]
    mov al, 2d
    mul ah
    add bx, ax
    call _line
    pop bx

    ;horiz numeration

    push bx
    mov bx, [es:start]
    mov al, byte [es:length]
    xor ah, ah
    add bx, ax
    mov [bx+2], word 0x0000
    mov [bx+4], word 0x02B3
    add bx, 3*2

    mov cx, 10d
    mov di, 0x0230 ; ASCII 0
    _horiz_num:
    mov [bx], di
    mov [bx+2], word 0x0220
    add bx, 4
    inc di
    loop _horiz_num

    mov cx, 6d
    mov di, 0x0241 ; ASCII A
    _horiz_dig:
    mov [bx], di
    mov [bx+2], word 0x0220
    add bx, 4
    inc di
    loop _horiz_dig

    ;borders
    sub bx, 2
    mov [bx], word 0x02BA
    add bx, ax ;ax has '+1 line' value
    mov [bx], word 0x02BA

    pop bx

    ;ASCII + vertical lines
    ;mov si, 0xFF ;total counter
    ;mov cx, 0x10 ;line length in chars
    ;di - used for tmp chars like space and pipe
    mov dl, 0x00 ;green-on-black ASCII 0
    xor ah, ah
    mov ah, [es:length]
    mov al, 3d
    mul ah
    add bx, ax
    sub bx, 2
    mov cx, 0x10 ;16 strings
    _main_loop:
        call _pipe
        
        ;draw vertical numeration
        mov di, 0x0240
        sub di, cx

        cmp cx, 0x06
        jg _digit
    ;add ascii offset
        add di,0x7

        _digit:

        mov [bx], di


        mov [bx+2], word 0x02B3 ;vertical thin line
        add bx, 4

        _chars:
            mov [bx], dx
            add bx, 2
            inc dl
            test dl, 0x0F ; % 16
            jz _last

            ;space
            mov di, 0x0220
            mov [bx], di
            add bx, 2
            jmp _chars

        _last:
            call _pipe
            add bx, [es:newline]    ; 0x17*4+2
            loop _main_loop


    jmp _sysexit

_line: ;destroys BX, CX!
    mov cx, 0x21 ;repeat 33 times (no borders)
    _line_loop:
    mov [bx], word dx
    add bx, 2
    loop _line_loop
    ret

;draw vertical line
_pipe:
    mov di, 0x02BA
    mov [bx], di
    add bx, 2
    ret



 _sysexit:
    mov ax, 0x4C00
    int 0x21
    ;ret

SECTION .data
    ;all for 80 width
    start dw 0x16C
    newline dw 0x17*4-2 ;?????
    bottom dw 0x16C+0xA0*19d
    length db 0xA0
    pagesize dw 0x0100