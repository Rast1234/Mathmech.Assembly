[bits 16]

;Imports=================================================
	extern int9
	extern int8
	extern save_mode
	extern set_mode
;Exports=================================================
	global dump_word
	global dump_byte
	global arg_parse
	global print_help
	global set_up
	global clean_up
	global print
	global newline
	global space
	global dump_dec
;Globals=================================================
	common bak_int9 4
	common bak_int8 4
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
	mov word [bak_int9+2], es
	mov word [bak_int9], bx
	
	;set new int9 handler
	mov ah, 0x25
	mov al, 0x09
	;DS is equal do CS
	mov dx, int9
	int 0x21

	;save old interrupt handler address
	mov ax, 0x3508
	int 0x21 ;AH:AL = 35:08 --> ES:BX = handler
	mov word [bak_int8+2], es
	mov word [bak_int8], bx
	
	;set new int08 handler
	mov ah, 0x25
	mov al, 0x08
	;DS is equal do CS
	mov dx, int8
	int 0x21


	;video mode
	call save_mode
	push word 0x1200
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

	;restore old int9 handler
	mov ax, 0x2509
	mov dx, [bak_int9]
	push ds
	push word [bak_int9+2]
	pop ds
	int 0x21 ;AH:AL = 25:09, DS:DX = new handler
	pop ds

	;restore old int8 handler
	mov ax, 0x2508
	mov dx, [bak_int8]
	push ds
	push word [bak_int8+2]
	pop ds
	int 0x21 ;AH:AL = 25:08, DS:DX = new handler
	pop ds

	push word [bak_video]
	call set_mode

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

print:
;========================================================
;	Prints 0-terminated string
;
;Arguments:
;		WORD asciz pointer
;
;Returns:
;		none
;========================================================
	push bp
	mov bp, sp
	push ax
	push bx
	push dx

	mov bx, [bp+4]
	.repeat:
		mov dl, [bx]
		cmp dl, 0x0
		je print.end
		mov ah, 0x02
		int 0x21
		inc bx
		jmp print.repeat
	.end:
	pop dx
	pop bx
	pop ax
	pop bp
	ret 2
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

dump_dec:
;========================================================
;	Prints word as DEC
;
;Arguments:
;		AX:	BYTE to print
;
;Returns:
;		none
;========================================================
	push ax
	push bx
	push cx
	push dx
	push di

	push ax
	push bx
	push cx
	push dx
	mov ah, 0x09
	mov al, ' '
	mov bh, 0
	mov bl, 0x0F
	mov cx, 5
	int 0x10
	pop dx
	pop cx
	pop bx
	pop ax
	
	mov di, dx
	push 0 
	mov bx,10 
	.one: 
		xor dx,dx 
		div bx 
		add dx,'0' 
		push dx 
		or al,al 
		jz dump_dec.two
		jmp dump_dec.one
	.two: 
		pop ax 
		or al,al 
		jz dump_dec.end

		;print!
		push ax
		push bx
		push cx
		push dx
		mov ah, 0x09
		mov bh, 0
		mov bl, 0x0F
		mov cx, 1
		int 0x10
		;move cursor back
		mov ah, 0x02
		mov bh, 0
		mov dx, di
		inc dl
		mov di, dx
		int 0x10
		pop dx
		pop cx
		pop bx
		pop ax

		jmp dump_dec.two
	.end: 
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret



SECTION .data
	symbols db '0123456789ABCDEF$'
	msg_help db 'This is angry snake game.',13,10
			db 'It`s mostly like normal snake,',13,10
			db 'but has several features.',13,10
			db 'See full list of rules',13,10
			db 'in game menu.',13,10,'$'
			db '',13,10,'$'
	newline db 13,10,0
	space db ' ',0