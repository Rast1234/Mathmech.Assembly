SECTION .text
	org 0x100

mov bh, 0x0E
call ega_get
mov ch, bl
mov bh, 0x0F
call ega_get
mov cl, bl

add cx, 332

;mov dx, 0x019A
mov bh, 0x0E
mov bl, ch
call ega_set
mov bh, 0x0F
mov bl, cl
call ega_set


;hide cursor
;	mov bh, 0x0A ;cursor start register
;	call ega_get
;	or bl, 0b00100000 ;Cursor Disable flag
;	call ega_set


xor ax, ax
int 0x16 ;wait keypress

;restore
;mov bh, 0x0A ;cursor start register
;	call ega_get
;	and bl, 0b11011111 ;Cursor Disable flag
;	call ega_set

jmp _sysexit

ega_set: ;set register value
					;BX = register:value
	push dx
	push ax

	;CRT Controller (CRTC) registers
	;ports 0x3B4/0x3B5 - monochrome display
	;ports 0x3D4/0x3D5 - color display

	; 0x3?4 : CRTC Address Register
	; 0x3?5 : CRTC Data Register

	mov dx, 0x03D4	;we want to address...
	mov al, bh
	out dx, al

	mov dx, 0x03D5	;write to it..
	mov al, bl
	out dx, al

	pop ax
	pop dx
	ret

ega_get: ;read register value
					;BH = register
					;out : BL = value
	push dx
	push ax

	mov dx, 0x03D4	;we want to address...
	mov al, bh
	out dx, al

	mov dx, 0x03D5	;write to it..
	in al, dx
	mov bl, al

	pop ax
	pop dx
	
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
    mov ax, 0x4de0
    int 0x21
    ret

SECTION .data
        symbols db '0123456789ABCDEF'