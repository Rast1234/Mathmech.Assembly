[bits 16]
%define screen_size 80*60
;Imports=================================================
	extern dump_byte
	extern dump_word
	extern key_exit
	extern key_pause
;Exports=================================================
	global int9
	global game
;Globals=================================================
	common screen screen_size
	common bak_int9 4
	common key 1

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
	iret

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
		cmp bl, [key_exit]
		je game.end
		cmp bl, [key_pause]
		je game.pause

		.pause:
			mov ax, 0xDEAD
			;call dump_word
			jmp game.tick_end

		.tick_end:
			jmp game.tick
	.end:
	
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret