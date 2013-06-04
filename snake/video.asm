[bits 16]

;Imports=================================================
	extern dump_byte
	extern dump_word
	extern print
	extern newline
;Exports=================================================
	global save_mode
	global set_mode
	global draw_cell
;Globals=================================================
	common screen 4800
	common bak_video 2

SECTION .text
save_mode:
;========================================================
;	Back up current video settings
;
;Arguments:
;		none
;
;Returns:
;		(alters global values: stores video settings)
;========================================================
	push ax
	push bx
	mov ax, 0x0F00
	int 0x10
	;al - video mode
	;bh - video page
	;ah - width in characters
	mov ah, al
	mov al, bh
	mov [bak_video], word ax
	pop bx
	pop ax
	ret

set_mode:
;========================================================
;	Set video settings
;
;Arguments:
;		BYTE mode, BYTE page
;
;Returns:
;		none
;========================================================
	push bp
	mov bp, sp

	mov ax, [bp+4]
	mov al, ah
	xor ah, ah
	int 0x10

	mov ax, [bp+4]
	mov ah, 0x05
	int 0x10

	pop bp
	ret 2

draw_cell:
;========================================================
;	Draw 8*8 square cell with texture at coordinates
;
;Arguments:
;		BYTE x, BYTE y
;		WORD pixmap segment
;		WORD pixmap offset
;
;Returns:
;		none
;========================================================
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push es

	; [bp+4]  ; offset
	; [bp+6]  ; segment
	; [bp+8]  ; x:y

	mov cx, 0
	mov dx, 0
	push word [bp+6]
	pop es

	mov bx, [bp+8]

	mov al, bh ;x
	mov ah, 8
	mul ah
	mov di, ax

	mov al, bl ;y
	mov ah, 8
	mul ah
	mov si, ax

	mov cx, 0
	mov dx, 0

	mov bx, [bp+4]
	mov ax, 0

	.vrt:
		;mov ax, si
		;call dump_word
		push di
		mov dx, 0
		.hrz:
			push di
			push si
			mov al, byte [es:bx]
			push ax
			call draw_pixel
			;mov ax, di
			;call dump_word
			inc bx
			inc di ; x+1
			inc dx
			cmp dx, 8
			jb draw_cell.hrz
		pop di
		;push newline
		;call print
		inc si ; y+1
		inc cx
		cmp cx, 8
		jb draw_cell.vrt

	
	.end:
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 6

draw_pixel:
;========================================================
;	Draw 8*8 square cell with texture at coordinates
;
;Arguments:
;		WORD x
;		WORD y
;		WORD color
;
;Returns:
;		none
;========================================================
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx


	mov ax, [bp+4] ;actually a byte for AL
	mov ah, 0x0C
	mov bh, 0
	mov dx, [bp+6]
	mov cx, [bp+8]
	int 0x10

	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 6