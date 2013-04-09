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
	int 0x10
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

;=============================================
;=============================================
;=============================================
;=============================================

    ;do something useful
    _useful:


	;copy prev page?
	;logic:
	; -c -> clear after work (skip copying)
	; -no key -> restore after work
	mov bl,[_workmode]
	and bl, 0b00000001 ;mask
	cmp bl, byte [_workmode_clear]
	je _nocopy
		;copy all stuff (by default)
		mov ah, byte [_old_mode]
		mov al, byte [_old_page]
		call _mem_calc
		;dx - mem start
		;bx - page size (bytes)
		mov ax, dx
		;call dump_word
		mov ax, bx
		;call dump_word

		mov ax, dx
		mov cx, bx
		mov bx, ds

		mov si, 0x0
		mov di, _page_dump

		;AX:SI = src
		;BX:DI = dst
		;CX = counter (words!)
		call _mem_copy

		;store cursor position
		mov bh, 0x0E
		call ega_get
		mov ch, bl
		mov bh, 0x0F
		call ega_get
		mov cl, bl
		mov word [_cursor], cx

		;store cursor position(dos)
		mov ah, 3
		mov bh, [_old_page]
		int 0x10
		mov [_dos_cursor], dx



	_nocopy:
		;do nothing

    ;set mode=================================
    xor ax, ax
    mov al, byte [_mode]
    cmp al, 1 	; 0,1 -> 40x25
	jg _wide
		;narrow mode (40x25)
		mov word [_start], (3+40*3)*2
		mov word [_newline], (4+4)*2
		mov word [_bottom],  (3+40*(3+17))*2
		mov word [_line_length], 0d40*2
	_wide:
	;or al, 0b10000000 ;high bit up
	int 0x10 ;set mode
	mov al, byte [_page]
	mov ah, 0x05
	int 0x10 ;set page

	;hide cursor
	mov bh, 0x0A ;cursor start register
	call ega_get
	or bl, 0b00100000 ;Cursor Disable flag
	call ega_set

	;get actual mode/page
    mov ax, 0F00h
	int 0x10 ;get vmode
	mov [_mode], al
	mov [_page], bh

	;set blink/intensity
	;mov ax, 0x1003 ;Set Pallette Registers service
	mov bl,[_workmode]
	and bl, 0b00000010 ;mask
	shr bl, 1 ;bit #1 to #0
	;0 - intensify
	;1 - blinking
	;int 0x10 ;set pallette reg
	call ega_blinking
 



	;memory works
	mov ah, byte [_mode]
	mov al, byte [_page]
	call _mem_calc
	;dx - start
	;bx - page size in words
	mov [_mem_start], dx
	push dx
	pop es ;video memory in ES

	;go

	;corners
	mov di, [_start]
	mov word [es:di], 0x02C9 ;left top
	add di, 2 ;after corner
	mov bx, 0x02CD ;horizontal double line
	call _line
	mov word [es:di], 0x02BB ;right top
	
	mov di, [_bottom]
	mov word [es:di], 0x02C8 ;left bottom
	add di, 2 ;after corner
	mov bx, 0x02CD ;horizontal double line
	call _line
	mov word [es:di], 0x02BC ;right bottom

	mov di, [_start]
	add di, word [_line_length]
	;we're under left top corner

	xor bx, bx ;reset code and attrs
    mov bh, 0xFF ;color
    mov cx, 0x10
    ;;;;;;;;drawing
    _main_loop:
    	mov word [es:di], 0x02BA ;vertical double border
    	add di, 2
    	_str_loop:
    		call _attr_mod
    		mov [es:di], word bx
    		add di, 2
    		
    		inc bl ;next code
    		test bl, 0x0F ; %16
    		jz _last

    		mov word [es:di], 0x0020 ;space
    		add di, 2
    		jmp _str_loop

    	_last:
    		
    		mov word [es:di], 0x02BA ;vertical double border
    		add di, [_newline]
    		loop _main_loop


    


    ;print diagnostics
    ; <TODO>
    mov di, word [_start]
    sub di, word [_line_length]
    mov cl, byte [_mode_msg_length]
    xor ch, ch
    mov bx, word _mode_msg
    mov al, byte [bx]
    mov ah, 0x02
    _mode_text:
    	mov [es:di], word ax
    	add di, 2
    	inc bx
    	mov al, byte [bx]
    	loop _mode_text
    add di, 2
    mov bl, [_mode]
    ;print digit
    call print_digit

    mov di, word [_bottom]
    add di, word [_line_length]
    mov cl, byte [_page_msg_length]
    xor ch, ch
    mov bx, word _page_msg
    mov al, byte [bx]
    mov ah, 0x02
    _page_text:
    	mov [es:di], word ax
    	add di, 2
    	inc bx
    	mov al, byte [bx]
    	loop _page_text
    add di, 2
    mov bl, [_page]
    ;print digit
    call print_digit


;______________________________________________
;______________________________________________

    xor ax, ax
    int 0x16 ;wait keypress
;______________________________________________
;______________________________________________
    ;restore original video modes
    xor ax, ax
    mov al, byte [_old_mode]
    ;or al, 0b10000000 ;high bit up
	int 0x10 ;set mode
	mov al, byte [_old_page]
	mov ah, 0x05
	int 0x10 ;set page

	;restore original page?
	;logic:
	; -c -> clear after work (skip copying)
	; -no key -> restore after work
	mov bl,[_workmode]
	and bl, 0b00000001 ;mask
	cmp bl, byte [_workmode_clear]
	je _norestore
		;restore all stuff (by default)
		mov ah, byte [_old_mode]
		mov al, byte [_old_page]
		call _mem_calc
		;dx - mem start
		;bx - page size

		mov ax, ds
		mov cx, bx
		mov bx, dx

		mov si, _page_dump
		mov di, 0x0

		;AX:SI = src
		;BX:DI = dst
		;CX = counter
		call _mem_copy

		;cursor!
		mov ah, 2
		mov bh, [_old_page]
		mov dx, [_dos_cursor]
		int 0x10


		
	_norestore:
		;do nothing

	;show cursor
	mov bh, 0x0A ;cursor start register
	call ega_get
	and bl, 0b11011111 ;Cursor Disable flag
	call ega_set
	

	;restore cursor position
	mov cx, [_cursor]
	mov bh, 0x0E
	mov bl, ch
	call ega_set
	mov bh, 0x0F
	mov bl, cl
	call ega_set

    jmp _sysexit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_mem_calc: ;calculates memory start
			;AH = mode
			;AL = page
			;
			;out: DX = memory start
			;out: BX = page size
	;video memory works
	mov bx, 0x100 ;pagesize (tmp)
	cmp ah, 0x01
	jg _mem_page_wide
		; narrow:
		mov bx, 0x0080
	_mem_page_wide:
		mov dx, 0xB800
		cmp byte ah, 0x7
		jne _mem_mode_continue
			mov dx, 0xB000
		_mem_mode_continue:
			;add pagesize to memory segment start
			mov cl, al
		    xor ch, ch
		    _mem_pages:
		    add dx, bx
		    loop _mem_pages
	shl bx, 4 ;4 - in bytes
	ret

_mem_copy: ;copy piece of memory
			;AX:SI = src
			;BX:DI = dst
			;CX = counter
	push ds
	push es

	push ax
	pop ds
	push bx
	pop es

	cld
	rep movsb

	pop es
	pop ds
	ret


_attr_mod:  ;mutate colors
			;BX = current attr:code
			;CX = current line
	xchg bh, bl ;patch
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

	jmp _col_sequence ;default


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
	xchg bh, bl ;patch
	pop ax
	ret

_line:
	mov cx, 0x20-1
	_line_loop:
	mov [es:di], word bx
	add di,2
	loop _line_loop
	ret

print_digit:
			;BL = digit
	mov bh, 0x01
	add bl, 0x30
	mov [es:di], bl
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
			mov bl, [_workmode]
			or bl, [_workmode_clear]
			mov [_workmode], bl
		jmp _process_end

		_set_blink:
			mov bl, [_workmode]
			or bl, [_workmode_blink]
			mov [_workmode], bl
		jmp _process_end

	_process_end:
	pop ax
	ret

ega_set: ;set register value
					;BX = register:value
	push dx
	push ax

	;CRT Controller (CRTC) registers
	;ports 0x3B4/0x3B5 - monochrome display
	;ports 0x3D4/0x3D5 - color display

	; 0x3?4 : CRTC Address Register
	; 0x3?5 : CRTC Data Register

	mov dx, 0x03D4	;we want to address...
	mov al, bh
	out dx, al

	mov dx, 0x03D5	;write to it..
	mov al, bl
	out dx, al

	pop ax
	pop dx
	ret

ega_get: ;read register value
					;BH = register
					;out : BL = value
	push dx
	push ax

	mov dx, 0x03D4	;we want to address...
	mov al, bh
	out dx, al

	mov dx, 0x03D5	;write to it..
	in al, dx
	mov bl, al

	pop ax
	pop dx
	
	ret

ega_blinking:
				;BL=1 - blink, 0 - no blink
	push dx
	push ax

	mov dx, 0x03DA
	in al, dx ;initialize attribute address register

	mov dx, 0x03C0	;AA register
	mov al, 0x10 ;mode control register
	out dx, al

	mov dx, 0x03C0	;Mode Control Register now
	in al, dx
	shl bl, 3
	; 0bxxxx!xyz
	; 0b....@...
	and al, 0b11110111 ;kill it
	or al, bl ;1 if 1, 0 if 0


	mov dx, 0x03C0	;Mode Control Register now
	out dx, al

	pop ax
	pop dx

	ret

__help:
	mov al, [_state]
	mov al, byte [_cur_arg]
    mov ah, 0x9
    mov dx, _help_msg
    int 0x21
    jmp _sysexit


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



_sysexit:
    mov ax, 0x4c00
    int 0x21
    ret


SECTION .data
        _state db 0
        symbols db '0123456789ABCDEF'
        _help_msg db "Usage: -h(elp) -p(age)X -m(ode)Y -b(link) -c(learscreen)",13,10
					db "Example: v.com -p3 -m2 -b",13,10,'$'
        _mode db 3
        _page db 0
        _mem_start dw 0x0
        _newline dw 0d24*2+0d24*2
        _line_length dw 0d80*2
        _cur_arg db 0
        _old_page db 0
        _old_mode db 0
        _old_mem_start dw 0x0
        _cursor dw 0
        _dos_cursor dw 0
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
        _start dw (0d23+0d80*3)*2 ; -> 23,  v 3, words
        _bottom dw (0d23+0d80*(3+17))*2 ; -> 23,  v 20, words

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
	_page_dump resb 0d4096 ;max video page size?