;Piano ver.1:
;
;exit on ESC
;uses int 0x09
;use keyboard to make some noise
;	TODO:
;		control built-in beeper
;		make noise on keys
;		remember pressed keys (omg) 1 2 3 -> 2 1 3
;		half-tones (chromatic)
;		internal melody switch
;		?????
;		PROFIT!
;
;		octave = 7 keys
;				+5 half-tones
;			*3	=	36 keys
;
;	     q w e r t y u i o p [ ]
;	     a s d f g h j k l ; ' ENTER
;	LSHIFT z x c v b n m , . / RSHIFT
;	


SECTION .text
	org 0x100

_main:
	mov ah, 0x09
	mov dx, welcome_msg
	int 0x21

	;save old interrupt handler address
	mov ax, 0x3509
	int 0x21 ;AH:AL = 35:09 --> ES:BX = handler
	mov word [ds:_backup+2], es
	mov word [ds:_backup], bx
	
	;set new int9 handler
	mov ah, 0x25
	mov al, 0x09
	;DS is equal do CS
	mov dx, _cool_int9
	int 0x21

	;infinite loop
	mov cx, 0x0
	call _infinite

	;restore old int9 handler
	mov ax, 0x2509
	mov dx, [ds:_backup]
	push ds
	push word [ds:_backup+2]
	pop ds
	int 0x21 ;AH:AL = 25:09, DS:DX = new handler
	pop ds

	mov ah, 0x09
	mov dx, quit_msg
	int 0x21
    jmp _sysexit
;=========================================
_infinite:
	inc cx
	mov ax, cx
	;call dump_word
	mov ah, 0x02
	mov dl, 0x09 ;ASCII TAB
	int 0x21
	

	call buf_pop ;reads into AL
	call dump_byte ;prints AL
	call magic
	call print_newline
	cmp al, [ExitScanCode] ;esc?
	jne _infinite
	ret

magic:
	push ax
	; takes scancode in AL
	;works with keypress buffer

	cmp al, 0x80 ; press or release?
	jb keypress
	jae keyrelease

	keypress:
		;is this key OKey?
		cmp al, 0x10
		jb endmagic
		cmp al, 0x1B
		jbe oct1_press

		; al > 0x1B
		cmp al, 0x1C	;enter
		je oct2_press
		cmp al, 0x1E
		jb endmagic
		cmp al, 0x28
		jbe oct2_press

		; al > 0x28
		cmp al, 0x2A
		je oct3_press
		cmp al, 0x2C
		jb endmagic
		cmp al, 0x36
		jbe oct3_press
		ja endmagic

		oct1_press:
					;	10..1B
			call key_push
			call make_noise
			jmp endmagic

		oct2_press:
					;	1C, 1E..28
			call key_push
			;	normalize:
			cmp al, 0x1C
			je _oct2_enter
			;	or just do it
			add al, 2 	; 0x1E -> 0x20
			jmp _oct2_ok
			_oct2_enter:
				mov al, 0x2B  ; last
			_oct2_ok:

			call make_noise
			jmp endmagic

		oct3_press:
					;	2A, 2C..36
			call key_push
			;	normalize:
			cmp al, 0x2A
			je _oct3_lshift
			;	or just do it
			add al, 5	; 0x2C -> 0x31
			jmp _oct3_ok
			_oct3_lshift:
				mov al, 0x30
			_oct3_ok:
			call make_noise
			jmp endmagic

	keyrelease:
		; filter first 9C (enter release)
		; filter releases of unpressed keys

	endmagic:
	pop ax
	ret

key_push:
		; AL = valid scancode to push
	push bx
	mov bx, keys
	dec bx
	_try_push:
		inc bx
		cmp bx, keys_end
		je _sysexit		;	FATAL
		cmp byte [bx], 0x0
		jne _try_push
	;BX has addr of first zero
	mov [bx], al
	call dump_keybuf
	pop bx
	ret

key_pop:
	
	ret

make_noise:
	push ax
	push dx
	push ax
	mov ah, 0x09
	mov dx, tone_msg
	int 0x21
	pop ax
	call dump_byte
	call print_newline
	; 10..1B - first octave
	; 20..2B - second
	; 30..3B - third



	pop dx
	pop ax
	ret

_cool_int9:
	;reads keyboard stuff into buffer
	_waitbuffer:
		in al, 0x64 ;keyboard status port
		test al, 0b10 ;buffer not empty?
		jne _waitbuffer ;wait for data

	in al, 0x60 ;get scancode from port

	call buf_push
	mov [tail], di

	in al, 61h ; Keyboard control register
	mov ah,al
	or al, 10000000b   ; Acknowledge bit
	out 61h, al ;send acknowledge
	mov al, ah
	out 61h, al ;restore control register

	mov al, 20h ;Send EOI (end of interrupt)
	out 20h, al ; to the 8259A PIC.
	;jmp far [_backup]
	iret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;FUNCTIONS;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dump_keybuf:
	push ax
	push bx
	push dx
	mov bx, keys
	dec bx
	mov ah, 0x02
	mov dl, 0x3C	; <
	int 0x21
	mov ah, 0x02
	mov dl, 0x20	; space
	int 0x21
	_dump_repeat:
		inc bx
		mov al, [bx]
		call dump_byte
		mov ah, 0x02
		mov dl, 0x20 	; space
		int 0x21
		cmp bx, keys_end-1
		jb _dump_repeat

	mov ah, 0x02
	mov dl, 0x3E	; >
	int 0x21
	pop dx
	pop bx
	pop ax
	ret

buf_push:
	;pushes AL
	mov si, [head]
	mov di, [tail]
	
	mov [di], byte al ;di always points to free cell
	;push ax
	;mov ax, di
	;call dump_word
	;mov ax, [buf_end]
	;call dump_word
	;pop ax
	inc di
	cmp di, [buf_end] ;rollback
	je _just_round
	jmp _just_end
	_just_round:
		sub di, [buf_size]
		jmp _just_end
	_beep:
		mov ah, 0x02
		mov dl, 0x14 ;ASCII Note
		int 0x21
		call print_newline
		jmp _just_end
	_just_end:

	mov [tail], di
	ret

buf_pop:
	;pops into AL
	mov si, [head]
	mov di, [tail]
	_wait_for_data:
		cmp si, di
		je _wait_for_data
	mov al, [si]
	inc si 
	cmp si, [buf_end]
	je read_round
	jmp _read_end

	read_round:
		sub si, [buf_size]
	
	_read_end:
		mov [head], si
	ret

	
print_newline:
	push ax
	push dx
	mov ah, 0x09
	mov dx, newline
	int 0x21
	pop dx
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



_sysexit:
    mov ax, 0x4c00
    int 0x21
    ret


SECTION .data
        symbols db '0123456789ABCDEF$'
        newline db 13,10,'$'
        welcome_msg db "Casio MIDI piano initialized.",13,10,"$"
        tone_msg db "Tone:	","$"
		quit_msg db "End of line, program.",13,10,"$"
		ExitScanCode db 0x01 ;escape pressed
		buffer times 0x10 db 0
		head dw buffer  ;pointer to buffer[0]
		tail dw buffer  ;pointer to buffer[0]
		buf_end dw head ;pointer to buffer[last]
		buf_size dw head - buffer
		keys db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  ; 16 zeros
		keys_end db $

		


SECTION .bss
		_backup resd 1
