[bits 16]
%define cell_size 16
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
	extern repaint
	extern place_object
;Exports=================================================
	global int9
	global int8
	global game
	global msg_pause
	global handle_cell
;Globals=================================================
	common screen 2000  ; 2400
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
	je int8.lol
	dec word [delay]
	.lol:
	popf
	jmp far [bak_int8]
	
	;mov     al, 0x20    ;послать сигнал конец-прерывания
	;out     0x20,al     ; контроллеру прерываний 8259
	;iret

handle_cell:
;========================================================
;	Cell handler
;	make cell decay to 'null'
;
;Arguments:
;		AX: x : y
;		BX: cell ptr
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

	mov dx, [bx]
	; DL = obj_id
	; DH = timer
	cmp dh, 0  ;if cell has 0 ttl, don't touch it
	je handle_cell.end

	dec dh  ;else dec its timer by 1
	cmp dh, 0 ;is it time to die?
	je handle_cell.decay
	jne handle_cell.end

	.decay:
		;replace with 'null' if timer reached 0
		mov dx, 0x0000  ; 'null' 

		;paint this because it won't get touched by repaint function
		push bx
		mov bl, 0
		call get_object
		call draw_object
		pop bx


	.end:
	mov [bx], dx  ; finally, store object in field
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret

gui:
;========================================================
;	GUI handler
;	draw useful info in the top of game field
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

	; set cursor pos
	mov ah, 0x02
	mov bh, 0
	mov dx, 0
	int 0x10

	; write something
	mov ah, 0x09
	mov al, 'S'
	mov bh, 0 ;page - text mode only?
	mov bl, 0b00001111
	mov cx, 10
	int 0x10

	.end:
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret


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

	;fill game field with 'null' texture
	mov si, 0  ; repaint ALL
	call repaint

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

			;mov [screen+0], word 1
			;mov [screen+2], word 0
			;mov [screen+80], word 2
			;mov [screen+82], word 2
			
			mov ax, 0x0000
			mov bl, 0
			call place_object

			mov ax, 0x0001
			mov bl, 1
			call place_object

			mov ax, 0x0100
			mov bl, 2
			call place_object

			mov ax, 0x0101
			mov bl, 1
			call place_object

			jmp game.tick_end

		.tick_end:  ; Things to do after each game tick
			mov si, 1  ; optimal repaint flag
			call repaint  ; refresh game field
			call gui  ; refresh gui
			.sleep:  ; sleep
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