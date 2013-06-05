[bits 16]
%define screen_size 80*60
;Imports=================================================
	extern dump_byte
	extern dump_word
	extern key_exit
	extern key_pause
	extern print
	extern print_help
	extern get_object
	extern draw_cell
	extern draw_object
	extern dump_object
	extern newline
	extern dump_pixmap
	extern test_colors
	extern fill_cell
;Exports=================================================
	global int9
	global int8
	global game
	global msg_pause
;Globals=================================================
	common screen screen_size
	common bak_int9 4
	common bak_int8 4
	common key 1
	common delay 2

SECTION .text
int9:
;========================================================
;	Int 9 keyboard service handler
;
;Arguments:
;		n/a
;
;Returns:
;		(alters global values: key)
;========================================================
	push ax
	.waitbuffer:
		in al, 0x64 ;keyboard status port
		test al, 0b10 ;buffer not empty?
		jne int9.waitbuffer ;wait for data

	in al, 0x60 ;get scancode from port
	mov [key], al

	in al, 61h ; Keyboard control register
	mov ah,al
	or al, 10000000b   ; Acknowledge bit
	out 61h, al ;send acknowledge
	mov al, ah
	out 61h, al ;restore control register

	mov al, 20h ;Send EOI (end of interrupt)
	out 20h, al ; to the 8259A PIC.
	;jmp far [bak_int9]
	pop ax
	iret

int8:
;========================================================
;	Int 8 timer interrupt handler
;
;Arguments:
;		n/a
;
;Returns:
;		(alters global values: delay)
;========================================================
	pushf
	cmp word [delay], 0
	je _lol
	dec word [delay]
	_lol:
	popf
	jmp far [bak_int8]
	
	;mov     al, 0x20    ;послать сигнал конец-прерывания
	;out     0x20,al     ; контроллеру прерываний 8259
	;iret


game:
;========================================================
;	Game handler (main loop)
;
;Arguments:
;		none
;
;Returns:
;		none
;========================================================
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	
	.tick:
		mov bl, [key]
		; Things to do before each game tick
		mov [delay], word 10

		; mask to ignore press/release difference
		and bl, 0b01111111  
		; now decide what to do
		cmp bl, [key_exit]
		je game.escape
		cmp bl, [key_pause]
		je game.paused

		jmp game.tick_end

		.escape:  ; Leave game NOW
			jmp game.end

		.paused:  ; Pause/resume game
			mov bl, 1
			call get_object
			;call dump_object
			;call dump_pixmap
			call draw_object
			

			jmp game.tick_end

		.tick_end:  ; Things to do after each game tick
			; sleep
			.sleep:
				cmp [delay], word 0
				ja game.sleep
			jmp game.tick
	.end:
	
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret

SECTION .data
	msg_pause db 'Game paused',0