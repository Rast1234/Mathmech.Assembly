[bits 16]

;Imports=================================================
	extern int9
	extern save_mode
	extern set_mode
;Exports=================================================
	global dump_word
	global dump_byte
	global arg_parse
	global print_help
	global set_up
	global clean_up
;Globals=================================================
	common screen 80*60
	common bak_int9 4
	common bak_video 2

SECTION .text
arg_parse:
;========================================================
;	Command-line arguments parser
;		reads command line string, changes
;		global vars/flags
;
;Arguments:
;		none
;
;Returns:
;		AX:	exit - 1 if want to exit program
;========================================================
		push bx
		push cx
		push dx
		xor ax, ax
		xor ch, ch
		mov cl, byte [es:0x80]
		mov bx, 0x80
		cmp cl, 0x0
		je arg_parse.end
		.reading:
			inc bx
			mov dl, byte [es:bx]
			; compares, jumps here
			cmp dl, 'h'
			je arg_parse.call_help
			; ...
			jmp arg_parse.next

			;useful stuff:
			.call_help:
				call print_help
				mov ax, word 0x1
				jmp arg_parse.next
			; ...

			.next:
			loop arg_parse.reading

		.end:
		pop dx
		pop cx
		pop bx
		ret

set_up:
;========================================================
;	Sets up and stores old environment:
;		interrupt handlers:
;			keyboard
;			timer
;		video mode
;
;Arguments:
;		none
;
;Returns:
;		(alters global values: saves old environment)
;========================================================
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	;save old interrupt handler address
	mov ax, 0x3509
	int 0x21 ;AH:AL = 35:09 --> ES:BX = handler
	mov word [ds:bak_int9+2], es
	mov word [ds:bak_int9], bx
	
	;set new int9 handler
	mov ah, 0x25
	mov al, 0x09
	;DS is equal do CS
	mov dx, bak_int9
	int 0x21

	;video mode
	call save_mode
	mov ax, 0x1200
	call set_mode
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret

clean_up:
;========================================================
;	Restore old environment:
;		interrupt handlers:
;			keyboard
;			timer
;		video mode
;
;Arguments:
;		none
;
;Returns:
;		none
;========================================================	
	;restore video mode
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	push word [bak_video]
	call set_mode

	;restore old int9 handler
	mov ax, 0x2509
	mov dx, [ds:bak_int9]
	push ds
	push word [ds:bak_int9+2]
	pop ds
	int 0x21 ;AH:AL = 25:09, DS:DX = new handler
	pop ds
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret



print_help:
;========================================================
;	Prints help message
;
;Arguments:
;		none
;
;Returns:
;		none
;========================================================
	push ax
	push dx
	mov   dx, msg_help
    mov   ah, 0x09
    int   0x21
    pop dx
    pop ax
	ret

dump_word:
;========================================================
;	Prints word as HEX
;
;Arguments:
;		AX:	WORD to print
;
;Returns:
;		none
;========================================================
	xchg al, ah
	call dump_byte
	xchg al, ah
	call dump_byte
	ret

dump_byte:
;========================================================
;	Prints byte as HEX
;
;Arguments:
;		AL:	BYTE to print
;
;Returns:
;		none
;========================================================
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


SECTION .data
		symbols db '0123456789ABCDEF$'
		msg_help db 'Help here',13,10,'$'
