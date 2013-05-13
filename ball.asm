; ball on edge

SECTION .text
	org 0x100

_main:
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

	;video mode
	call save_mode
	mov ax, 0x1200
	call set_mode

	;set mouse stuff
	call init_mouse

	call draw_frame

	;infinite loop
	call _infinite

	;handlers off
	call kill_mouse

	;restore video mode
	mov ax, word [_videomode]
	call set_mode

	;restore old int9 handler
	mov ax, 0x2509
	mov dx, [ds:_backup]
	push ds
	push word [ds:_backup+2]
	pop ds
	int 0x21 ;AH:AL = 25:09, DS:DX = new handler
	pop ds


	jmp _sysexit

_infinite:
	mov al, [key]
	cmp al, [ExitScanCode]
	jne _infinite
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;FUNCTIONS;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
data_seg_ref dw 0
draw_frame:
	; assume we're in 640*480*16
	;horizontal lines
	mov cx, word [frame_sz] ;x from
	mov si, word [frame_sz+4] ;x to
	mov ah, 0x0C
	mov al, [frame_color]
	mov bh, 0
	_draw_horiz:
		push si
		mov dx, word [frame_sz+2]
		int 0x10
		mov dx, word [frame_sz+6]
		int 0x10
		inc cx
		pop si
		cmp cx, si
		jb _draw_horiz
	
	mov dx, word [frame_sz+2] ;y from
	mov si, word [frame_sz+6] ;y to
	mov ah, 0x0C
	mov al, [frame_color]
	mov bh, 0
	_draw_vert:
		push si
		mov cx, word [frame_sz]
		int 0x10
		mov cx, word [frame_sz+4]
		int 0x10
		inc dx
		pop si
		cmp dx, si
		jb _draw_vert

	ret
draw_ball:
	
	ret

init_mouse:
	mov [cs:data_seg_ref], ds
	mov	ax, 0x0	;init
	int	0x33
	mov	ax, 0x1	;show cursor
	int	0x33

	;AX = 000Ch
	;ES:DX = адрес обработчика
	;СХ = условие вызова
	;бит 0 - любое перемещение мыши
	;бит 1 - нажатие левой кнопки
	;бит 2 - отпускание левой кнопки
	;бит 3 - нажатие правой кнопки
	;бит 4 - отпускание правой кнопки
	;бит 5 - нажатие средней кнопки
	;бит 6 - отпускание средней кнопки
	;СХ = 0000h - отменить обработчик
	mov ax, 0x000C
	push cs
	pop es
	mov dx, mouse_event
	mov cx, 0b00000111
	int 0x33

	ret

kill_mouse:
	mov	ax,0x000C	; remove handler
	mov	cx, 0x0
	int	0x33
	ret

mouse_event:
	push ax
	push bx
	push cx
	push dx
	push ds
	push word [cs:data_seg_ref]
	pop ds ;restore to current
	mov	ax, 2	; спрятать курсор
	int	0x33

	mov	ah,0x0C	; вывести точку
	mov	al,0x0A
	int	0x10

	mov	ax, 1	; показать курсор
	int	0x33
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	retf

save_mode:
	mov ax, 0x0F00
	int 0x10
	;al - video mode
	;bh - video page
	;ah - width in characters
	mov ah, al
	mov al, bh
	mov [_videomode], word ax
	ret

set_mode: ; AX: mode, page
	push ax
	push ax
	mov al, ah
	xor ah, ah
	int 0x10
	pop ax

	mov ah, 0x05
	int 0x10
	pop ax
	ret

_cool_int9:
	_waitbuffer:
		in al, 0x64 ;keyboard status port
		test al, 0b10 ;buffer not empty?
		jne _waitbuffer ;wait for data

	in al, 0x60 ;get scancode from port

	mov [key], byte al

	in al, 61h ; Keyboard control register
	mov ah,al
	or al, 10000000b   ; Acknowledge bit
	out 61h, al ;send acknowledge
	mov al, ah
	out 61h, al ;restore control register

	mov al, 20h ;Send EOI (end of interrupt)
	out 20h, al ; to the 8259A PIC.
	jmp far [_backup]
	;iret


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
		key db 0
		ExitScanCode db 0x01 ;escape pressed
		frame_sz 	dw 0x0064, 0x0032 ;word x1, word y1		= 100* 50
		 			dw 0x0258, 0x0190 ;word x2, word y2	= 600*400
		frame_color db 12
		ball_radius dw 0x0010
		ball_pos dw 0x0064, 0x0032
		ball_color db 10

SECTION .bss
		_backup resd 1
		_videomode resw 1