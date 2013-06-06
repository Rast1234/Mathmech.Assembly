[bits 16]
%define cell_size 16
%define screen_size_x 40
%define screen_size_y 25
;Imports=================================================
	extern collision_none
	extern collision_tail
	extern print
	extern newline
	extern space
	extern dump_byte
	extern dump_word
;Exports=================================================
	global get_object
	global get_object_id
	global init_objects
	global destroy_objects
	global dump_object
	global dump_pixmap
	global place_object
	global empty
;Globals=================================================
	common screen 2000

SECTION .text
get_object:
;========================================================
;	Determine object type from byte
;
;Arguments:
;		BL: object number (from game field)
;
;Returns:
;		BX: object descriptor address
;========================================================
	;0 -> empty
	;1 -> head
	;2 -> tail
	; ...
	push si
	mov si, lookup
	mov bh, 0
	shl bx, 1  ; BL*2
	add si, bx
	mov bx, [si] ;pointer to object descripor
	pop si
	ret

get_object_id:
;========================================================
;	Get byte (object number) to place in game field
;
;Arguments:
;		BX: object descriptor
;
;Returns:
;		BL: object number
;========================================================
	push ax
	push si
	mov si, lookup
	mov al, 0
	.search:
		cmp bx, [si]
		je .found

		inc al
		add si, 2
		jmp get_object_id.search
	.found:
		mov bl, al
		mov bh, 0  ; for clearance
	pop si
	pop ax
	ret

init_objects:
;========================================================
;	Initialize object structures:
;		load pixmaps from files
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

; DOS occupies all free mem for .COM program
; need to release some memory first
	;mov bx, sp 
	;add bx, 0x10 - 1          ;find first segment
	;mov cl,4                  ;beyond end of program
	;shr bx,cl 
	mov bx, 4096 ; just works
	mov ah, 0x4a              ;adjust memory reserved
	int 0x21

	mov si, lookup
	.foreach:
		mov dx, [si]
		cmp dx, 0
		je init_objects.end

	;open file
		add dx, 10  ; point to filename
		mov ax, 0x3D00  ; open file for reading
		int 0x21
		; AX = filehandle
		mov [handle], ax

	;calculate required size
	; TODO: really calculate, dont read just one frame!
		;mov bx, [si]
		;mov ax,  cell_size*cell_size ; one frame size
		;mov dl, [bx+1]
		;mov dh, 0
		;mul dx  ; framesize * frames = read bytes
		; result in DX:AX
		mov ax, 256

		mov [read_size], ax

	;allocate memory
		mov bx, [read_size]
		shr bx, 4  ; / 16
		add bx, 1  ; + 1 to fit all
		mov ah, 0x48
		int 0x21	;	fails with 'no memory available'
		push ax
		jc init_objects.fail
		jnc init_objects.ok
		.fail:
			;mov ax, 0xDEAD
			;call dump_word
			jmp init_objects.next
		.ok:
			;call dump_word
			jmp init_objects.next
		.next:
		pop ax
		mov bx, [si]
		mov [bx+8], ax
		mov [bx+6], word 0

	;read from file



		mov di, [si]
		mov dx, [di+6]
		mov bx, [handle]
		mov cx, [read_size]
		mov bx, [handle]
		push ds
		push word [di+8]
		pop ds
		mov ah, 0x3F
		int 0x21
		pop ds

	;close file
		mov ah, 0x3E  ; close filehandle
		mov bx, [handle]
		int 0x21
		add si, 2
		jmp init_objects.foreach

	.end:
	;call dump_lookup
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

destroy_objects:
;========================================================
;	Free pixmap memory
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

	mov si, lookup
	.foreach:
		mov dx, [si]
		cmp dx, 0
		je destroy_objects.end

	;deallocate memory
		mov bx, [si]
		push es
		push word [bx+8]
		pop es
		mov ah, 0x49
		int 0x21
		pop es

		add si, 2
		jmp destroy_objects.foreach

	.end:
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

dump_lookup:
;========================================================
;	Dumps object lookup table
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

	mov si, lookup
	.foreach:
		mov dx, [si]
		cmp dx, 0
		je dump_lookup.end
		mov ax, [si]
		call dump_word

		add si, 2
		push newline
		call print
		jmp dump_lookup.foreach

	.end:
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

dump_object:
;========================================================
;	Dumps object
;Arguments:
;		BX = object ref
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

	mov al, byte [bx]
	call dump_byte
	push space
	call print

	mov al, byte [bx+1]
	call dump_byte
	push space
	call print

	mov ax, word [bx+2]
	call dump_word
	push space
	call print

	mov ax, word [bx+4]
	call dump_word
	push space
	call print

	mov ax, word [bx+6]
	call dump_word
	mov ax, word [bx+8]
	call dump_word
	push space
	call print

	add bx, 10
	push word bx
	call print

	.end:
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

dump_pixmap:
;========================================================
;	Dumps pixmap
;Arguments:
;		BX = object ref
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
	
	push word [bx+8]
	pop es
	mov bx, [bx+6]
	mov cx, cell_size*cell_size
	
	.foreach:
		mov ax, [es:bx]
		call dump_byte
		inc bx
		loop dump_pixmap.foreach

	.end:
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

place_object:
;========================================================
;	Places object as id:ttl at game field
;Arguments:
;		AX: x : y
;		BL: object type
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

	mov di, screen
	
	mov dx, ax
	mov al, dl ;y
	mov ah, screen_size_x
	shl ah, 1
	mul ah

	mov dl, dh
	mov dh, 0
	shl dl, 1
	add ax, dx

	; y * 40 + x
	add di, ax  ; move to cell

	mov cl, bl  ; obj type
	call get_object
	mov bl, [bx]
	mov ch, bl  ; store ttl
	
	mov [di], cx

	.end:
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret

SECTION .data
;Named objects, in format:
;	BYTE	ttl (living time in game ticks, 0 is infinity)
;	BYTE	sprites (number of frames, minimum 1)
;	WORD	score (cost earned by player, SIGNED)
;	WORD	collision handler (near ptr to function)
;	DWORD	pixmap pointer (far ptr to pixel array, = 0)
;	ASCIZ	name (also a bitmap filename)

objects ;start descriptor table

	empty	db 0, 1
			dw 0, collision_none
			dd 0
			db 'NULL',0

	head	db 0, 1
			dw 0, collision_none
			dd 0
			db 'head',0

	tail	db 0, 1
			dw 0, collision_tail
			dd 0
			db 'tail',0

;Object lookup table
lookup	dw empty, head, tail
		dw 0  ; end of table

SECTION .bss
	handle resw 1
	read_size resw 1
