[bits 16]
%define cell_size 16
%define screen_size_x 40
%define screen_size_y 25
;Imports=================================================
	extern dump_byte
	extern dump_word
	extern print
	extern newline
	extern handle_cell
	extern get_object
;Exports=================================================
	global save_mode
	global set_mode
	global draw_cell
	global draw_object
	global test_colors
	global fill_cell
	global repaint
;Globals=================================================
	common screen 2000  ; 2400
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


draw_object:
;========================================================
;	Draw object by reference
;
;Arguments:
;		AH: x
;		AL: y
;		BX: object handler
;
;Returns:
;		none
;========================================================
	push ax
	push word [bx+8]  ; pixmap segment
	push word [bx+6]  ; pixmap offset
	call draw_cell
	ret

draw_cell:
;========================================================
;	Draw square cell with texture at coordinates
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
	mov ah, cell_size
	mul ah
	mov di, ax

	mov al, bl ;y
	mov ah, cell_size
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
			cmp dx, cell_size
			jb draw_cell.hrz
		pop di
		;push newline
		;call print
		inc si ; y+1
		inc cx
		cmp cx, cell_size
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
;	Draw single pixel
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
	push es

	;mov ax, 0xA000  ; video memory
	;mov es, ax

	; slow draw routine using int 0x10
	mov ax, [bp+4] ;actually a byte for AL, color
	mov ah, 0x0C
	mov bh, 0  ; page
	mov dx, [bp+6]  ; y
	mov cx, [bp+8]  ; x

	add dx, cell_size*5
	int 0x10

	; fast draw routine using VGA bitplanes
	; bitplanes:
	;	x x x x 3 2 1 0
	;	x x x x I R G B
	;			I for Intensity
	;mov dx, 0x03C4  ; some VGA port
	;mov ax, 0x0f00
	;out dx, ax
	;mov di, 0
	;mov cx, 1
	;mov al, 0x01
	;mov [es:di], al

	pop es
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 6

fill_cell:
;========================================================
;	Fill square cell with single color at coordinates
;
;Arguments:
;		BYTE x, BYTE y
;		BYTE 0, BYTE color
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

	; [bp+4]  ; offset
	; [bp+6]  ; x:y

	mov cx, 0
	mov dx, 0

	mov bx, [bp+6]

	mov al, bh ;x
	mov ah, cell_size
	mul ah
	mov di, ax

	mov al, bl ;y
	mov ah, cell_size
	mul ah
	mov si, ax

	mov cx, 0
	mov dx, 0

	mov ax, [bp+4]

	.vrt:
		;mov ax, si
		;call dump_word
		push di
		mov dx, 0
		.hrz:
			push di
			push si
			push ax
			call draw_pixel
			;mov ax, di
			;call dump_word
			inc di ; x+1
			inc dx
			cmp dx, cell_size
			jb fill_cell.hrz
		pop di
		;push newline
		;call print
		inc si ; y+1
		inc cx
		cmp cx, cell_size
		jb .vrt

	
	.end:
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 4

test_colors:
;========================================================
;	Test all 256 colors
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
	push di
	push si
	push es

	mov ax, 0x0000 ;pos
	mov bx, 0x0 ;color
	.foreach:
		push ax
		push bx
		call fill_cell

		inc bx
		inc ah
		cmp bx, 100
		jb test_colors.foreach

	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

repaint:
;========================================================
;	Draw whole game field
;	don't redraw fields with id = 0
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
	push di
	push si
	push es
	
	mov cx, 0 ;y
	mov dx, 0 ;x
	mov di, screen ;cell ptr

	.vrt:
		mov dx, 0
		.hrz:
			mov bx, di  ; cell
			mov ah, dl
			mov al, cl
			call handle_cell  ; process this cell

			mov bl, [di]  ; id
			cmp bl, 0
			je repaint.cell_end
			call get_object
			mov ah, dl
			mov al, cl
			call draw_object
			.cell_end:
			add di, 2
			inc dx
			cmp dx, 40
			jb repaint.hrz
		inc cx
		cmp cx, 25
		jb repaint.vrt

	
	.end:
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
