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
	call draw_ball

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
	push ax
	push bx
	push cx
	push dx
	push di
	push si
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
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
draw_ball:
	push ax
	push bx
	push cx
	push dx
	push di
	push si

	mov bx, 1
	xor cx, cx
	mov cl, byte [ball_radius]
	sub bx, cx ; f = 1-radius
	mov si, 1 ; wtfX
	mov al, -2
	imul cl ; -2*radius
	mov di, ax ; wtfY
	mov cx, 0 ; X
	xor dx, dx
	mov dl, byte [ball_radius] ; Y

	;four initial dots
	push word [ball_pos] ; X0
	mov ax, word [ball_pos+2] ;Y0
	add ax, [ball_radius]
	push ax
	push word [ball_color]
	call draw_pixel

	push word [ball_pos] ; X0
	mov ax, word [ball_pos+2] ;Y0
	sub ax, [ball_radius]
	push ax
	push word [ball_color]
	call draw_pixel

	mov ax, word [ball_pos] ;X0
	add ax, [ball_radius]
	push ax
	mov ax, word [ball_pos] ;X1
	sub ax, [ball_radius]
	push ax
	push word [ball_pos+2] ; Y0
	push word [ball_color]
	call draw_line

	;while (x < y)
	_while_x_lt_y:
		;if (f >= 0)
		cmp bx, 0
		jl _while_ok
			dec dx ; y--
			add di, 2 ; wtfY += 2
			add bx, di ; f += wtfY
		_while_ok:
		inc cx ; x++
		add si, 2 ; wtfX += 2
		add bx, si ; f += wtfX

		; 8 draws
		mov ax, word [ball_pos] ;X0
		add ax, cx
		push ax
		mov ax, word [ball_pos] ;X1
		sub ax, cx
		push ax
		mov ax, word [ball_pos+2] ;Y0
		add ax, dx
		push ax
		push word [ball_color]
		call draw_line

		

		mov ax, word [ball_pos] ;X0
		add ax, cx
		push ax
		mov ax, word [ball_pos] ;X1
		sub ax, cx
		push ax
		mov ax, word [ball_pos+2] ;Y0
		sub ax, dx
		push ax
		push word [ball_color]
		call draw_line

		

		mov ax, word [ball_pos] ;X0
		add ax, dx
		push ax
		mov ax, word [ball_pos] ;X1
		sub ax, dx
		push ax
		mov ax, word [ball_pos+2] ;Y0
		add ax, cx
		push ax
		push word [ball_color]
		call draw_line

		
		mov ax, word [ball_pos] ;X0
		add ax, dx
		push ax
		mov ax, word [ball_pos] ;X1
		sub ax, dx
		push ax
		mov ax, word [ball_pos+2] ;Y0
		sub ax, cx
		push ax
		push word [ball_color]
		call draw_line


		; finally...
		cmp cx, dx
		jl _while_x_lt_y

	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax

	ret
draw_pixel:
		;on stack:
		;	X_POS
		;	Y_POS
		;	COLOR
		;	ip
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

draw_line:	;draws horizontal line
		;on stack:
		;	X1
		;	X2
		;	Y
		;	COLOR
		;	ip
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	mov ax, [bp+4]	; color
	mov bx, [bp+6]	; Y
	mov cx, [bp+8]	; X2
	mov dx, [bp+10]	; X1
	cmp cx, dx
	ja _while_draw
	xchg cx, dx ;patch if end < begin
	_while_draw:
		push dx
		push bx
		push ax
		call draw_pixel
		inc dx
		cmp dx, cx
		jbe _while_draw

	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 8



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
	;mov	ax, 2	; спрятать курсор
	;int	0x33

	;mov	ah,0x0C	; вывести точку
	;mov	al,0x0A
	;int	0x10
	;remove old ball anyway
	; too bad, causes blinking
	cmp [lock_flag], byte 1
	je mouse_event.end_noflag
	mov [lock_flag], byte 1

	cmp ax, 0x0001
	je mouse_event.move
	cmp ax, 0x0002
	je mouse_event.press
	cmp ax, 0x0004
	je mouse_event.release

.move:
	and bx, 0x01 ;mask to ignore right button
	cmp bx, 0x01
	je mouse_event.drag
	jne mouse_event.just_move
.drag:
	cmp byte [fail_flag], 1
	je mouse_event.end
	call in_frame
	cmp ax, 1
	jne mouse_event.end
		;move 'em all!
		cmp word [coordinates], 0 ;critical
		je _sysexit
		cmp word [coordinates+2], 0 ;error
		je _sysexit

		;calculate diff between coord and current
		;restore from backups
		;add'em to frame_sz
		;check if they're in 640*480
		;draw

		push word [frame_color]
		mov [frame_color], word 0
		call draw_frame
		pop word [frame_color]
		push word [ball_color]
		mov [ball_color], word 0
		call draw_ball
		pop word [ball_color]

		sub cx, word [coordinates]
		sub dx, word [coordinates+2]
		push cx
		mov cx, 4
		mov si, bak_frame_sz
		mov di, frame_sz
		.restore1:
			mov ax, [si]
			mov [di], ax
			add di, 2
			add si, 2
			loop mouse_event.restore1
		mov cx, 2
		mov si, bak_ball_pos
		mov di, ball_pos
		.restore2:
			mov ax, [si]
			mov [di], ax
			add di, 2
			add si, 2
			loop mouse_event.restore2
		pop cx
		add [frame_sz], cx
		add [frame_sz+2], dx
		add [frame_sz+4], cx
		add [frame_sz+6], dx
		add [ball_pos], cx
		add [ball_pos+2], dx

		mov ax, [ball_radius]
		cmp word [frame_sz], ax
		jb mouse_event._drag_fail
		mov ax, 640
		sub ax, word [ball_radius]
		cmp word [frame_sz+4], ax
		ja mouse_event._drag_fail
		mov ax, [ball_radius]
		cmp word [frame_sz+2], ax
		jb mouse_event._drag_fail
		mov ax, 480
		sub ax, [ball_radius]
		cmp word [frame_sz+6], ax
		ja mouse_event._drag_fail


		call draw_frame
		call draw_ball
	jmp mouse_event._drag_fail
	jmp mouse_event.end
._drag_fail:
	mov byte [fail_flag], 1
	mov cx, 4
	mov si, bak_frame_sz
	mov di, frame_sz
	.reset1:
		mov ax, [si]
		mov [di], ax
		add di, 2
		add si, 2
		loop mouse_event.reset1
	mov cx, 2
	mov si, bak_ball_pos
	mov di, ball_pos
	.reset2:
		mov ax, [si]
		mov [di], ax
		add di, 2
		add si, 2
		loop mouse_event.reset2

	call draw_frame
	call draw_ball
	jmp mouse_event.end
.just_move:
	push word [ball_color]
	mov [ball_color], word 0
	call draw_ball
	pop word [ball_color]
	call draw_frame 
	call move_circle
	call draw_ball
	jmp mouse_event.end
.press:
	mov [coordinates], cx
	mov [coordinates+2], dx
	mov cx, 4
	mov si, frame_sz
	mov di, bak_frame_sz
	.backup1:
		mov ax, [si]
		mov [di], ax
		add di, 2
		add si, 2
		loop mouse_event.backup1
	mov cx, 2
	mov si, ball_pos
	mov di, bak_ball_pos
	.backup2:
		mov ax, [si]
		mov [di], ax
		add di, 2
		add si, 2
		loop mouse_event.backup2
	jmp mouse_event.end
.release:
	mov byte [fail_flag], 0
	mov [coordinates], word 0
	mov [coordinates+2], word 0
	jmp mouse_event.end
.end:
	mov [lock_flag], byte 0
.end_noflag:
	;mov	ax, 1	; показать курсор
	;int	0x33
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	retf

move_circle:
		; CX = hrz cursor pos
		; DX = vrt cursor pos
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	; probe distances to different dimensions of frame
	; will store current line in di (1,2,3,4)
	; and best distance in si
	mov di, 0
	mov si, 0xFFFF
	one:	; 1) line X1,Y1--X2,Y1 (hrz)
			;compare Y for now
			mov ax, [frame_sz+2]
			mov bx, dx
			call _abs ; distance in AX
			cmp ax, si
			ja two
			;or it's better than distance in SI?
			;check if it's in actual range
			cmp cx, word [frame_sz]
			jb two
			cmp cx, word [frame_sz+4]
			ja two
			;everthing ok
			mov si, ax
			mov di, 1
	two:	; 2) line X1,Y2--X2,Y2 (hrz)
			mov ax, [frame_sz+6]
			mov bx, dx
			call _abs
			cmp ax, si
			ja three
			;or it's better than distance in SI?
			;check if it's in actual range
			cmp cx, word [frame_sz]
			jb three
			cmp cx, word [frame_sz+4]
			ja three
			;everthing ok
			mov si, ax
			mov di, 2
	three:	; 3) line X1,Y1--X1,Y2 (vrt)
			mov ax, [frame_sz]
			mov bx, cx
			call _abs
			cmp ax, si
			ja four
			;or it's better than distance in SI
			;check if it's in actual range
			cmp dx, word [frame_sz+2]
			jb four
			cmp dx, word [frame_sz+6]
			ja four
			;everthing ok
			mov si, ax
			mov di, 3
	four:	; 4) line X2,Y1--X2,Y2 (vrt)
			mov ax, [frame_sz+4]
			mov bx, cx
			call _abs
			cmp ax, si
			ja enough
			;or it's better than distance in SI
			;check if it's in actual range
			cmp dx, word [frame_sz+2]
			jb enough
			cmp dx, word [frame_sz+6]
			ja enough
			;everthing ok
			mov si, ax
			mov di, 4
	enough:
			; ???
			cmp di, 1
			je enough.one
			cmp di, 2
			je enough.two
			cmp di, 3
			je enough.three
			cmp di, 4
			je enough.four
			jmp enough.end ;should never happen
		.one:
			mov ax, [frame_sz+2]
			mov [ball_pos+2], ax
			jmp enough.set_hrz
		.two:
			mov ax, [frame_sz+6]
			mov [ball_pos+2], ax
			jmp enough.set_hrz
		.three:
			mov ax, [frame_sz]
			mov [ball_pos], ax
			jmp enough.set_vrt
		.four:
			mov ax, [frame_sz+4]
			mov [ball_pos], ax
			jmp enough.set_vrt
		.set_hrz:
			cmp cx, word [frame_sz]
			jb enough.hrz_min
			cmp cx, word [frame_sz+4]
			ja enough.hrz_max
			;if it's in between X1 and X2
			mov [ball_pos], cx
			jmp enough.end
			.hrz_min:
				mov ax, [frame_sz]
				mov [ball_pos], ax
				jmp enough.end
			.hrz_max:
				mov ax, [frame_sz+4]
				mov [ball_pos], ax
				jmp enough.end
		.set_vrt:
			cmp dx, word [frame_sz+2]
			jb enough.vrt_min
			cmp dx, word [frame_sz+6]
			ja enough.vrt_max
			;if it's in between Y1 and Y2
			mov [ball_pos+2], dx
			jmp enough.end
			.vrt_min:
				mov ax, [frame_sz+2]
				mov [ball_pos+2], ax
				jmp enough.end
			.vrt_max:
				mov ax, [frame_sz+6]
				mov [ball_pos+2], ax
				jmp enough.end
		
	.end:
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

_abs:
	;in: AX, BX
	;out: AX = abs(AX-BX)
	cmp ax, bx
	jae _abs.ok
	xchg ax, bx
.ok:	sub ax, bx
	ret

in_frame:
	;	CX:	hrz pos
	;	DX: vrt pos
	;out: AX: 1 if inside, 0 if outside
	mov ax, 0
	cmp cx, word [frame_sz]
	jb in_frame.end
	cmp cx, word [frame_sz+4]
	ja in_frame.end
	cmp dx, word [frame_sz+2]
	jb in_frame.end
	cmp dx, word [frame_sz+6]
	ja in_frame.end
	mov ax, 1
	.end:
	ret
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
		key db 0
		ExitScanCode db 0x01 ;escape pressed
		frame_sz 	dw 0x0064, 0x0032 ;word x1, word y1		= 100* 50
		 			dw 0x0258, 0x0190 ;word x2, word y2	= 600*400
		frame_color db 12
		ball_pos dw 0x0064, 0x0032
		ball_color db 10, 0x0
		ball_radius db 3, 0x0
		coordinates dw 0x0, 0x0
		bak_frame_sz dw 0,0,0,0
		bak_ball_pos dw 0,0
		fail_flag db 0
		lock_flag db 0
SECTION .bss
		_backup resd 1
		_videomode resw 1