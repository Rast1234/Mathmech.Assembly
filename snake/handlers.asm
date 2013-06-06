[bits 16]
%define cell_size 16
%define act_exit 3
%define act_none 0
%define mutation_mask_cross_transparent	0b00000001
%define mutation_mask_godmode			0b00000010
%define mutation_mask_noclip			0b00000100
%define dir_stop 0
%define dir_up 1
%define dir_down 2
%define dir_left 3
%define dir_right 4
;Imports=================================================
	extern dump_byte
	extern dump_word
	extern key_exit
	extern key_pause
	extern print
	extern print_help
	extern get_object
	extern get_object_id
	extern draw_cell
	extern draw_object
	extern dump_object
	extern newline
	extern dump_pixmap
	extern test_colors
	extern fill_cell
	extern repaint
	extern place_object
	extern dump_dec

	extern key_exit
	extern key_pause
	extern key_up
	extern key_down
	extern key_left
	extern key_right
	extern key_fast
	extern key_slow
	extern key_cross

	extern head

	extern mutation
	extern speed
	extern init_field
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
	common paused 1
	common snake 2
	common length 2

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

	
	mov al, [key]
	and al, 0x7F
	cmp al, [key_exit]
	je int9.set_exit

	mov al, [key]
	cmp al, [key_pause]
	je int9.set_pause

	cmp al, [key_cross]
	je int9.toggle_cross
	cmp al, [key_fast]
	je int9.faster
	cmp al, [key_slow]
	je int9.slower
	cmp al, [key_up]
	je int9.up
	cmp al, [key_down]
	je int9.down
	cmp al, [key_left]
	je int9.left
	cmp al, [key_right]
	je int9.right
	jmp int9.set_none

	.set_pause:
		mov al, byte [paused]
		not al
		mov [paused], al
		mov [delay], word 0
		jmp int9.end

	.set_exit:
		mov [action], byte act_exit
		mov [delay], word 0
		jmp int9.end

	.set_none:
		mov [action], byte act_none
		jmp int9.end

	.toggle_cross:
		;inc byte [mutation]
		mov al, [mutation]
		and al, byte mutation_mask_cross_transparent
		not al
		mov ah, [mutation]
		or ah, byte mutation_mask_cross_transparent
		and al, ah
		mov [mutation], al
		jmp int9.end
	.faster:
		cmp word [speed], 0x0000
		je int9.end
		dec word [speed]
		jmp int9.end
	.slower:
		cmp word [speed], 0xFFFF
		je int9.end
		inc word [speed]
		jmp int9.end

	.up:
		cmp [direction], byte dir_down
		je int9.stop
		mov [direction], byte dir_up
		jmp int9.end
	.down:
		cmp [direction], byte dir_up
		je int9.stop
		mov [direction], byte dir_down
		jmp int9.end
	.left:
		cmp [direction], byte dir_right
		je int9.stop
		mov [direction], byte dir_left
		jmp int9.end
	.right:
		cmp [direction], byte dir_left
		je int9.stop
		mov [direction], byte dir_right
		jmp int9.end

	.stop:
		mov [direction], byte dir_stop
		jmp int9.end
	.end:
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
	mov dx, 0x0000 ; y:x
	int 0x10

	; write something
	mov al, [action]
	call dump_byte

	; set cursor pos
	mov ah, 0x02
	mov bh, 0
	mov dx, 0x0100 ; y:x
	int 0x10

	mov al, [mutation]
	call dump_byte

	; set cursor pos
	mov ah, 0x02
	mov bh, 0
	mov dx, 0x0103 ; y:x
	int 0x10

	mov ah, 0
	mov ax, [speed]
	mov bx, 0xffff
	sub bx, ax
	mov ax, bx
	call dump_dec

	; set cursor pos
	mov ah, 0x02
	mov bh, 0
	mov dx, 0x0203 ; y:x
	int 0x10	
	mov ax, [ticks]
	call dump_dec

	; set cursor pos
	mov ah, 0x02
	mov bh, 0
	mov dx, 0x0400 ; y:x
	int 0x10
	cmp [paused], byte 0
	je gui.no_pause
	jne gui.is_pause
	.is_pause:

		push msg_pause
		call print
		jmp gui.end_pause

	.no_pause:
		mov ah, 0x09
		mov al, ' '
		mov bh, 0x00
		mov bl, 0x00
		mov cx, [len_msg_pause]
		int 0x10
		jmp gui.end_pause

	.end_pause:

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

	call init_field

	mov si, 0  ; repaint ALL for the first time
	call repaint


	.tick:
		; Things to do before each game tick
		mov ax, word [speed]
		mov [delay], ax

		; now decide what to do
		cmp [action], byte act_exit
		je game.escape
		
		;do regular ordinary snake meal time
		cmp [paused], byte 0
		jne game.tick_end_paused
		;call food_handler
		call snake_handler

		jmp game.tick_end

		.escape:  ; Leave game NOW
			jmp game.end

		.tick_end:  ; Things to do after each game tick
			cmp [paused], byte 1
			je game.tick_end_paused
			; unpaused:
				inc word [ticks]
				mov si, 1  ; optimal repaint flag
				call repaint  ; refresh game field
			.tick_end_paused:
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

snake_handler:
;========================================================
;	Snake handler (replace head and chain)
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

	mov ax, [snake]
	mov bx, head
	call get_object_id

	cmp [direction], byte dir_stop
	je snake_handler.end
	cmp [direction], byte dir_up
	je snake_handler.move_up
	cmp [direction], byte dir_down
	je snake_handler.move_down
	cmp [direction], byte dir_left
	je snake_handler.move_left
	cmp [direction], byte dir_right
	je snake_handler.move_right
	jmp snake_handler.end

	.move_up:
		dec al
		jmp snake_handler.move_it
	.move_down:
		inc al
		jmp snake_handler.move_it
	.move_left:
		dec ah
		jmp snake_handler.move_it
	.move_right:
		inc ah
		jmp snake_handler.move_it

	.move_it:
		mov [snake], ax
		call place_object
	
	.end:
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret


SECTION .data
	msg_pause	db 'Game paused',0
	len_msg_pause dw $ - msg_pause - 1
	action		db 0
		;special actions:
			; 0 - none
			; 3 - exit
	direction	db 0
		;directions:
		;	0 - stop
		;	1 - up
		;	2 - down
		;	3 - left
		;	4 - right
	ticks dw 0
