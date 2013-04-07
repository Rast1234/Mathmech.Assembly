;get current video mode and active page

SECTION .text
	org 0x100

_main:
	
	call get_mode
	jmp exit
	symbols db '0123456789ABCDEF'

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

get_mode:
	mov ax, 0F00h
	int 10h
	call dump_byte ;print al - video mode
	mov al, bh
	call dump_byte ;print video page
	mov al, ah
	call dump_byte ;print width in characters
	ret



exit:
	mov ax, 4c00h
	int 21h
	ret