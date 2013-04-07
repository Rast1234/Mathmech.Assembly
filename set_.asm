;set video mode and active page
SECTION .text
	org 0x100

_main:
	symbols db '0123456789ABCDEF'
	mov bh, [es:80h]
	cmp bh, 4h
	je tests
	jmp exit
quit:
	jmp exit
tests:
	mov bh, [es:82h]	
	mov bl, [es:84h]
	sub bh, 30h
	sub bl, 30h
	
	cmp bh, 0
	jne test_1
	cmp bl, 7
	jg quit
	xor ah, ah
	mov al, bh
	int 10h
	mov ah, 5
	mov al, bl
	int 10h
	;mode 0
	jmp exit
test_1:
	cmp bh, 1
	jne test_2
	cmp bl, 7
	jg quit
	xor ah, ah
	mov al, bh
	int 10h
	mov ah, 5
	mov al, bl
	int 10h
	;mode 1
	jmp exit
test_2:
	cmp bh, 2
	jne test_3
	cmp bl, 3
	jg quit
	xor ah, ah
	mov al, bh
	int 10h
	mov ah, 5
	mov al, bl
	int 10h
	;mode 2
	
	jmp exit
test_3:
	cmp bh, 3
	jne test_7
	cmp bl, 3
	jg quit
	xor ah, ah
	mov al, bh
	int 10h
	mov ah, 5
	mov al, bl
	int 10h
	;mode 3
	
	jmp exit
test_7:
	cmp bh, 7
	jne exit
	cmp bl, 0
	jne exit
	xor ah, ah
	mov al, bh
	int 10h
	mov ah, 5
	xor al, al
	int 10h
	
	jmp exit

dump_word:	; print AX
	xchg al, ah
	call dump_byte
	xchg al, ah
	call dump_byte
	ret

dump_byte:	; print AL
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

exit:
	mov ax, 4c00h
	int 21h
	ret