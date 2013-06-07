[bits 16]
%define cell_size 16
%define mutation_mask_cross_transparent	0b00000001
%define mutation_mask_godmode			0b00000010
%define mutation_mask_noclip			0b00000100
;Imports=================================================
	extern dump_word

	extern empty
	extern head
	extern tail
	extern wall_portal
	extern wall_wall
	extern wall_kill
	extern food_inc
	extern food_dec
	extern food_bad
	extern snake
	extern get_object_id
	extern place_object
	extern game_over
;Exports=================================================
	global key_exit
	global key_pause
	global key_up
	global key_down
	global key_left
	global key_right
	global key_fast
	global key_slow
	global key_cross

	global init_config
	global speed
	global mutation
	global init_field
;Globals=================================================
	common screen 2000  ; 2400 ;screen_size, MACRO DOESN'T WORK
	common key 1
	common paused 1
	common length 2
	common score 2
	common delta 1

SECTION .text
init_config:
;========================================================
;	Initialize default values, game field, etc.
;
;Arguments:
;		none
;
;Returns:
;		(alters global values: screen, key, ...)
;========================================================
	push ax
	push bx
	push cx

	mov [key], byte 0x0
	mov [paused], byte 0x0
	mov [length], word 1
	mov [score], word 0
	mov [delta], byte 0

	mov cx, 640/cell_size*(480/cell_size-5)
	mov bx, screen
	.fill:
		mov [bx], word 0
		add bx, 2
		loop init_config.fill

	mov cx, 1000-2
	mov bx, snake
	.snack:
		mov [bx], word 0x0000
		add bx, 2
		loop init_config.snack

	pop cx
	pop bx
	pop ax
	ret

init_field:
;========================================================
;	Initialize default field (walls, food, snake)
;
;Arguments:
;		none
;
;Returns:
;		(alters global values: screen)
;========================================================
	push ax
	push bx
	push cx

	;fill edges with portals
	mov bx, wall_portal
	call get_object_id
	mov ax, 0x0000
	.portal_vrt:
		mov ah, 0
		call place_object
		mov ah, 39
		call place_object

		inc al
		cmp al, 25
		jb init_field.portal_vrt
	mov ax, 0x0000
	.portal_hrz:
		mov al, 0
		call place_object
		mov al, 24
		call place_object

		inc ah
		cmp ah, 40
		jb init_field.portal_hrz
	
	;make some walls
	mov bx, wall_wall
	call get_object_id
	mov ax, 0x0A0A
	.wall_vrt:
		call place_object
		inc al
		cmp al, 20
		jb init_field.wall_vrt

	mov ax, 0x0A0A

	;and death walls
	mov bx, wall_kill
	call get_object_id
	.kill_hrz:
		mov al, 10
		call place_object
		mov al, 20
		call place_object

		inc ah
		cmp ah, 30
		jb init_field.kill_hrz

	; place food
	mov bx, food_inc
	call get_object_id
	mov ah, 23
	mov al, 15
	call place_object

	; place food
	mov bx, food_inc
	call get_object_id
	mov ah, 32
	mov al, 10
	call place_object

	; place food
	mov bx, food_dec
	call get_object_id
	mov ah, 33
	mov al, 10
	call place_object

	; place food
	mov bx, food_bad
	call get_object_id
	mov ah, 37
	mov al, 15
	call place_object

	; place snake's head
	mov bx, head
	call get_object_id
	mov ah, 20
	mov al, 15
	call place_object
	mov [snake], ax

	pop cx
	pop bx
	pop ax
	ret


SECTION .data
	speed		dw 0x00  ; fastest
	mutation	db 0x0  ; game changer
keys:
	key_exit	db 0x01	 ; ESC scancode
	key_pause	db 0x19	 ; P
	key_up		db 0x48  ; up arrow
	key_down	db 0x50  ; down arrow
	key_left	db 0x4B  ; left arrow
	key_right	db 0x4D  ; right arrow
	key_fast	db 0x0D  ; +
	key_slow	db 0x0C  ; -
	key_cross	db 0x0E  ; backspace
