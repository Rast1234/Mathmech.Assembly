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
	;call play_music
	;ret
	call magic
	call print_newline
	cmp al, [ExitScanCode] ;esc?
	jne _infinite
	call speaker_off
	ret

magic:
	push ax
	; takes scancode in AL
	;works with keypress buffer

	cmp al, 0x80 ; press or release?
	jb keypress
	jae keyrelease

	keypress:
		;for testing
		cmp al, 0x39  ; space pressed
		je magic_stop
		;for easter
		cmp al, 0x58  ; F12 pressed
		je magic_music
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
			mov ah, 1
			call key_push
			call make_noise
			jmp endmagic

		oct2_press:
					;	1C, 1E..28
			mov ah, 2
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
			mov ah, 3
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

		magic_stop:
			mov ah, 0
			call make_noise
			jmp endmagic

		magic_music:
			call speaker_off
			call play_music
			jmp endmagic			

	keyrelease:
		; filter first 9C (enter release)
		; filter releases of unpressed keys
		and al, 0x7F  ; kill high bit

		;is this key OKey?
		cmp al, 0x10
		jb endmagic
		cmp al, 0x1B
		jbe oct1_release

		; al > 0x1B
		cmp al, 0x1C	;enter
		je oct2_release
		cmp al, 0x1E
		jb endmagic
		cmp al, 0x28
		jbe oct2_release

		; al > 0x28
		cmp al, 0x2A
		je oct3_release
		cmp al, 0x2C
		jb endmagic
		cmp al, 0x36
		jbe oct3_release
		ja endmagic

		oct1_release:
					;	10..1B
			mov ah, 1
			call key_pop
			call make_noise
			jmp endmagic

		oct2_release:
					;	1C, 1E..28
			mov ah, 2
			call key_pop
			;	normalize:
			cmp al, 0x1C
			je _oct2_enter_
			;	or just do it
			add al, 2 	; 0x1E -> 0x20
			jmp _oct2_ok_
			_oct2_enter_:
				mov al, 0x2B  ; last
			_oct2_ok_:
			call make_noise
			jmp endmagic

		oct3_release:
					;	2A, 2C..36
			mov ah, 3
			call key_pop
			;	normalize:
			cmp al, 0x2A
			je _oct3_lshift_
			;	or just do it
			add al, 5	; 0x2C -> 0x31
			jmp _oct3_ok_
			_oct3_lshift_:
				mov al, 0x30
			_oct3_ok_:
			call make_noise
			jmp endmagic

	endmagic:
	pop ax
	ret

key_push:
		; AL = valid scancode to push
		; ignore if present
	push bx
	mov bx, keys
	dec bx
	_try_push:
		inc bx
		cmp bx, keys_end
		je _sysexit		;	FATAL
		cmp byte [bx], al
		je _key_push_end
		cmp byte [bx], 0x0
		jne _try_push
	;BX has addr of first zero
	mov [bx], al
	call dump_keybuf
	_key_push_end:
	pop bx
	ret

key_pop:
		; AL = valid scancode to find
		; returns:
		;		AL = last significant scancode
		;		AH = 0 to stop, or not altered
	; 1) find scancode
	; 2a) shift others if found
	; 2b) ignore if not found
	push bx
	mov bx, keys
	dec bx
	_try_pop:
		inc bx
		cmp bx, keys_end ;not found, finally
		je _key_pop_end
		cmp [bx], al
		jne _try_pop
	; BX has addr to erase
	call _shift_left
	call dump_keybuf
	_key_pop_end:
	;now find rightmost non-zero
	mov bx, keys
	dec bx
	_try_find:
		inc bx
		cmp byte [bx], 0x0
		jne _try_find
	dec bx
	cmp bx, keys-1
	je _not_found
	;BX has addr of last tone
	mov al, [bx]
	jmp _key_pop_finally_end

	_not_found:
		mov ah, 0 ;will stop the sound
	_key_pop_finally_end:
	pop bx
	ret
_shift_left:
	push ax
	push bx
		; BX = current address to erase
	;replace current with next
	;until current is not zero
	dec bx
	_shift_loop:
		inc bx
		mov ax, [bx+1] ;next
		mov [bx], ax ;replace current with next
		cmp byte [bx], 0
		jne _shift_loop
	pop bx
	pop ax
	ret
make_noise:
		; AL - tone
		; AH - octave nr. (1, 2, 3), 0 to stop
	push ax
	push bx
	push cx
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
	cmp ah, 0
	je _stop
	cmp ah, 1
	je _oct1
	cmp ah, 2
	je _oct2
	cmp ah, 3
	je _oct3

	_stop:
		call speaker_off
		jmp make_noise_end

	_oct1:
		sub al, 0x10
		mov bx, oct1
		jmp make_noise_ok
	_oct2:
		sub al, 0x20
		mov bx, oct2
		jmp make_noise_ok
	_oct3:
		sub al, 0x30
		mov bx, oct3	
		jmp make_noise_ok

	make_noise_ok:
	;AL is number of tone in octave
	;BX is octave pointer
	shl al, 1 	; x2 because tones stored as words
	mov ah, 0
	add bx, ax  ; move to tone
	mov ax, [bx]  ; store it
	call speaker_on

	make_noise_end:
	pop dx
	pop cx
	pop bx
	pop ax
	ret

speaker_on:
		; AX - tone
	;speaker magic
	push ax
	push ax
	mov al, 0b10110110 ;magic number to initialize Timer2
	out 0x43, al
	pop ax
	out 0x42, al  ; write LSB
	mov al, ah
	out 0x42, al  ; write MSB
	in al, 0x61
	or al, 0b000011 ;turn speaker ON
	out 0x61, al
	pop ax
	ret

speaker_off:
	push ax
	in al, 0x61
	and al, 0b11111100 ;turn speaker OFF
	out 0x61, al
	pop ax
	ret

play_music:
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	;save old interrupt handler address
	mov ax, 0x3508
	int 0x21 ;AH:AL = 35:08 --> ES:BX = handler
	mov word [ds:_backup2+2], es
	mov word [ds:_backup2], bx
	
	;set new int08 handler
	mov ah, 0x25
	mov al, 0x08
	;DS is equal do CS
	mov dx, _cool_int8
	int 0x21

	;play stuff
	mov cx, [m_count]
	mov di, m_notes
	mov si, m_delays
	_player:
		mov al, [di]
		call simplify
		call make_noise
		call dump_word
		mov ax, [si]
		call print_newline
		push di
		push si
		mov [delay], ax
		_alala:
			cmp [delay], word 0
			ja _alala
		pop si
		pop di
		inc di
		add si, 2
		loop _player


	call speaker_off


	;restore old int8 handler
	mov ax, 0x2508
	mov dx, [ds:_backup2]
	push ds
	push word [ds:_backup2+2]
	pop ds
	int 0x21 ;AH:AL = 25:08, DS:DX = new handler
	pop ds

	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

simplify:
		;AL = byte to play
		;return: AX = octave:byte
	; 001..013 - first
	; 101..113 - second
	; 201..213 - third
	; 
	cmp al, 0
	je s_silent
	cmp al, 13
	jbe s_1
	cmp al, 113
	jbe s_2
	cmp al, 213
	jbe s_3
	jmp s_silent

	s_silent:
		mov ax, 0x0000
		jmp s_end
	s_1:
		mov ah, 0x01
		add al, 15
		jmp s_end
	s_2:
		mov ah, 0x02
		sub al, 69
		jmp s_end
	s_3:
		mov ah, 0x03
		sub al, 153
		jmp s_end
	s_end:
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

_cool_int8:
			;DECs DI until 0, then sets SI=1
	pushf
	cmp word [cs:delay], 0
	je _lol
	dec word [cs:delay]
	_lol:
	popf
	jmp far [cs:_backup2]
	
	;mov     al, 0x20    ;послать сигнал конец-прерывания
	;out     0x20,al     ; контроллеру прерываний 8259
	iret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;FUNCTIONS;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dump_keybuf:
	ret
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
		keys_trailing_zero db 0
		keys_end db $-1

		;music magic

		; Small octave
		;Note 		C 		C# 		D 		D# 		E 		F 		F# 		G 		G# 		A 		A# 		B
		;Frequency 	130.81 	138.59 	146.83 	155.56 	164.81 	174.61 	185.00 	196.00 	207.65 	220.00 	233.08 	246.94
		oct1 dw		9121,	8609,	8126,	7670,	7239,	6833,	6449,	6087,	5746,	5423,	5119,	4831

		; First octave
		;Note		Mid C 	C# 		D 		D# 		E 		F 		F# 		G 		G# 		A 		A# 		B
		;Frequency 	261.63 	277.18 	293.66 	311.13 	329.63 	349.23 	369.99 	391.00 	415.30 	440.00 	466.16 	493.88
		oct2 dw		4560,	4304,	4063,	3834,	3619,	3416,	3224,	3043,	2873,	2711,	2559,	2415

		; Second octave
		;Note 		C 		C# 		D 		D# 		E 		F 		F# 		G 		G# 		A 		A# 		B
		;Frequency 	523.25 	554.37 	587.33 	622.25 	659.26 	698.46 	739.99 	783.99 	830.61 	880.00 	923.33 	987.77
		oct3 dw 	2280,	2152,	2031,	1917,	1809,	1715,	1612,	1521,	1436,	1355,	1292,	1207

		delay dw 0x0018 ;1 second?

		;	timing:	|========= 1+ second = 19 ======|
		m_notes  db  103,0, 103,0,103,0,103,0, 105,0, 105,0, 107,0, 103,0, 105,0 ;tram ta-da-da-da-ta tam-ta-tam
		 		 db  103,0, 103,0,103,0,103,0, 105,0, 105,0, 107,0, 103,0, 105,0 ;tram ta-da-da-da-ta tam-ta-tam
		 		 db  5,101,0, 103,101,0, 12,11,0, 8,7,0,    3,13,0,  101,13,0

		m_delays dw  3, 5,  1,2,  1,2,  1,2,     4,6, 4,5,   4,5,   4,6,   10,8
				 dw  3, 5,  1,2,  1,2,  1,2,     4,6, 4,5,   4,5,   4,6,   10,8
				 dw  2,4,3,    2,4,3,    2,4,3,   2,7,4,    2,4,3,   2,4,3


		m_count dw m_delays - m_notes


SECTION .bss
		_backup resd 1
		_backup2 resd 1