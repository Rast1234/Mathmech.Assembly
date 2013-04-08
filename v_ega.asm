;displays ASCII table
;works in different video modes
;uses video memory (WIP)
;processes command-line arguments
;restores video mode/page back

SECTION .text
	org 0x100

_main:
    ;get and save current modes
    mov ax, 0F00h
	int 10h
	mov [_old_mode], al
	mov [_old_page], bh


    ;CMD args parser
    mov cx, [es:0x80]
    xor ch, ch
    mov dx, cx
    
    cmp cl, 0x00 ;no args - just work.
    je _useful

    mov si, 0x82 ; ignore 81's space

    _read_loop:
        lodsb ;load cmd arg to al
        mov [_cur_arg], al ;offset
        lea bx, [_map] ;ascii
        xlat	;get table column from map
        		;al := bx

        lea bx, [_table] ;automata
        push ax
        xor dh, dh
        mov dl, byte [_state_count]
        xor ax, ax
        mov al, [_state]
        mul dx
        add bx, ax
        pop ax
        xlat
        mov [_state], al
        call __process_arg
        dec cx ;cmd length -1
        cmp cx, 1
        jg _read_loop

        ;end of parsing
        ;al - automata state
        cmp al, 4 ; -,/,m,p,h
        jle __help

    ;do something useful
    _useful:

;jmp _sysexit

    ;set mode
    xor ax, ax
    mov al, byte [_mode]
    cmp al, 1 	; 0,1 -> 40x25
	jg _wide
	mov [_start], word 0x0403 ; ->3, v4
	_wide:
	int 10h
	mov al, byte [_page]
	mov ah, 0x05
	int 10h

	;set blink/intensity
	mov ax, 0x1003 ;Set Pallette Registers service
	mov bl,[_workmode]
	and bl, 0b00000010 ;mask
	shr bl, 1 ;bit #1 to #0
	;0 - intensify
	;1 - blinking
	int 0x10


    ;set cursor pos
    mov ah, 0x02
    mov bh, byte [_page]
    mov dx, word [_start]
    int 0x10

    mov cx, 0x01
    mov bh, 0x20
    mov bl, 0x02
    call _cur_put
    call _cur_move
    ;call _cur_newline


    xor bx, bx ;reset code and attrs
    mov bl, 0xFF
    mov cx, 0x10
    ;;;;;;;;drawing
    _main_loop:
    	_str_loop:
    		call _attr_mod
    		call _cur_put
    		call _cur_move
    		
    		inc bh ;next code
    		test bh, 0x0F ; %16
    		jz _last

    		call _cur_move
    		jmp _str_loop

    	_last:
    		call _cur_newline
    		loop _main_loop

    ;print diagnostics
    mov bl, [red]
	or bl, [blue]
	or bl, [green]
	mov dx, word [_start]
	dec dh
	inc dl
	mov bh, byte [_mode_msg_length]
	mov cx, word _mode_msg
	call _cur_str_put

	or bl, [hicolor]
	mov bh, byte [_mode]
	add bh, 0x30
	call _cur_put

	xor bl, [hicolor]
	mov dx, word [_start]
	add dh, 16
	inc dl
	mov bh, byte [_page_msg_length]
	mov cx, word _page_msg
	call _cur_str_put

	or bl, [hicolor]
	mov bh, byte [_page]
	add bh, 0x30
	call _cur_put
    
    ;hide cursor
    mov dh, 24d
    call _cur_newline

    ;;;;;;;;over

    xor ax, ax
    int 0x16
    ;restore original video modes
    xor ax, ax
    mov al, byte [_old_mode]
	int 10h
	mov al, byte [_old_page]
	mov ah, 0x05
	int 10h

    jmp _sysexit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_attr_mod:  ;DX = current row:col
			;BX = current code:attrs
			;CX = current line
	;color behavior
	push ax
	mov ax, 0x10 ;because cx steps 15..0
	sub ax, cx
	cmp ax, 0x00
	je _col_sequence
	cmp ax, 0x01
	je _col_green_blink

	cmp ax, 0x0E
	je _col_a
	cmp ax, 0x0F
	je _col_b

	jmp _col_sequence ;defaule


	_col_sequence:
		inc bl
		jmp _col_end

	_col_green_blink:
		mov bl, [green]
		or bl, [blink]
		jmp _col_end

	_col_a:
		mov bl, [bred]
		or bl, [bblue]
		or bl, [green]
		or bl, [hicolor]
		jmp _col_end

	_col_b:
		mov bl, [bred]
		or bl, [bgreen]
		or bl, [blink]
		or bl, [red]
		or bl, [blue]
		or bl, [green]
		or bl, [hicolor]
		jmp _col_end


	_col_end:
	pop ax
	ret
_cur_put:	;DX = current row:col
			;BX = current code:attrs
	push ax
	push bx
	push cx
	mov ah, 0x09
	mov al, bh
	mov bh, byte [_page]
	mov cx, 0x01
	int 0x10
	pop cx
	pop bx
	pop ax
	ret

_cur_move: ;DX = current row:col
	push ax
	push bx
	xor ax, ax
	mov ah, 0x02
	mov bh, byte [_page]
	inc dl
	int 0x10
	pop bx
	pop ax
	ret
_cur_newline: ;DX = current row:col
	push ax
	push bx
	xor ax, ax
	mov ah, 0x02
	mov bh, byte [_page]
	inc dh
	sub dl, 31d ;move to begin of line
	int 0x10
	pop bx
	pop ax
	ret
_cur_str_put: ;DX = current row:col
			  ;BX = length:attrs
			  ;CX = string ptr
	push ax
	push bx
	push cx
	push es
	push bp

	push ds
	pop es 
	mov bp, cx
	mov ah, 0x13
	mov al, 0x01
	xor cx, cx
	mov cl, bh
	mov bh, byte [_page]
	int 0x10

	pop bp
	pop es
	pop cx
	pop bx
	pop ax
	ret


__process_arg:
	push ax
	xor ax, ax
	mov al, byte [_state]
	;call dump_byte
	cmp ax, 5
	je _set_mode
	cmp ax, 6
	je _set_page
	cmp ax, 7
	je _set_blink
	cmp ax, 8
	je _set_clear

	jmp _process_end

		_set_mode:
			mov al, byte [_cur_arg]
			sub al, 0x30
			cmp ax, 3
			jle _mode_ok
			cmp ax, 7
			je _mode_ok
			;TODO: write that something is wrong
			jmp _process_end
			_mode_ok:
				mov [_mode], byte al
		jmp _process_end

		_set_page:
			mov al, byte [_cur_arg]
			sub al, 0x30
			cmp ax, 7
			jle _page_ok
			;TODO: write that something is wrong

			jmp _process_end
			_page_ok:
				mov [_page], byte al
		jmp _process_end

		_set_clear:
			mov bx, [_workmode]
			or bx, [_workmode_clear]
			mov [_workmode], bx
		jmp _process_end

		_set_blink:
			mov bl, [_workmode]
			or bl, [_workmode_blink]
			mov [_workmode], bl
		jmp _process_end

	_process_end:
	pop ax
	ret

dump_word:	; print AX
	xchg al, ah
	call dump_byte
	xchg al, ah
	call dump_byte
	ret

dump_byte:; print AL
	push bx
	push cx
	push dx
	push ax
	push ax

	lea bx, [cs:symbols]
	shr al, 4
	xlat
	mov dl, al
	mov ah, 2
	int 21h
	pop ax
	and al, 0Fh
	xlat
	mov dl, al
	mov ah, 2
	int 21h
	
	pop ax
	pop dx
	pop cx
	pop bx
	ret

__help:
	mov al, [_state]
	mov al, byte [_cur_arg]
    mov ah, 0x9
    mov dx, _help_msg
    int 0x21
    jmp _sysexit

_sysexit:
    mov ax, 0x4de0
    int 0x21
    ret



exit:
	mov ax, 4c00h
	int 21h
	ret


SECTION .data
        _state db 0
        symbols db '0123456789ABCDEF'
        _help_msg db "Usage: -h(elp) -p(age) -m(ode)",13,10,'$'
        _mode db 3
        _page db 0
        _cur_arg db 0
        _old_page db 0
        _old_mode db 0
        _page_msg db 'page: '
        _page_msg_length db $-_page_msg
        _mode_msg db 'mode: '
        _mode_msg_length db $-_mode_msg
        _workmode db 0b00000000 	; bit flags: 76543210
        			   				; [0] - clear (if 1, do cls)
        			   				; [1] - blink (if 1, blink)
        _workmode_clear db 0b00000001 ;clear
        _workmode_blink db 0b00000010 ;blink
        
        ;for 80x25
        _start dw 0x0418 ; ->24, v4

        ;automata
	_state_count db 0d10

        ;      0 1 2 3 4 5 6 7 8 9
        ;      / - h m p D _ * b c	;	states:
  _table    db 1,1,2,2,2,2,0,2,2,2	;0 - init
            db 2,2,2,3,4,5,2,2,7,8	;1 - separator
            db 2,2,2,2,2,2,2,2,2,2	;2 - help
            db 2,2,2,2,2,5,2,2,2,2	;3 - mode
            db 2,2,2,2,2,6,2,2,2,2	;4 - page
            db 2,2,2,2,2,2,0,2,2,2	;5 - mode_digit
            db 2,2,2,2,2,2,0,2,2,2	;6 = page_digit
            db 2,2,2,2,2,2,0,2,2,2	;7 = blink?
            db 2,2,2,2,2,2,0,2,2,2	;8 = clear?


        ;ASCII-map: 
    _map    times 32 db 7       ;all (0..31)
            db 6                ; [space] (offset 32)
            times 12 db 7       ;all (33..44)
            db 1                ; - (45)
            db 7                ;all
            db 0                ; / (47)
            times 10 db 5		; Digits
            times 40 db 7       ;all (58..97)
            db 8 				;b (98)
            db 9 				;c (99)
            times 4 db 7 		;d,e,f,g
            db 2                ; h (104)
            db 7,7,7,7
            db 3 				; m (109)
            db 7,7
            db 4 				; p (112)
            times 15 db 7        ;all (113..127)

    ;colors:
    red 	db 0b00000100
    green 	db 0b00000010
    blue 	db 0b00000001
    blink   db 0b10000000
    bred	db 0b01000000
    bblue	db 0b00100000
    bgreen	db 0b00010000
    hicolor db 0b00001000
    ;COLORS:   0bBRGBHrgb
    ;	B - blinking
    ;	H - high color

SECTION .bss
	_page_dump db 