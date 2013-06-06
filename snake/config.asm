[bits 16]
%define cell_size 16
;Imports=================================================
	extern dump_word
;Exports=================================================
	global key_exit
	global key_pause
	global init_config
	global speed
;Globals=================================================
	common screen 2400;screen_size, MACRO DOESN'T WORK
	common key 1

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
	mov cx, 640/cell_size*480/cell_size
	mov bx, screen
	.fill:
		mov [bx], word 0
		add bx, 2
		loop init_config.fill
	pop cx
	pop bx
	pop ax
	ret

SECTION .data
	speed		dw 0x09  ; about 0.5 second
	key_exit	db 0x01	; ESC scancode
	key_pause	db 0x19	; P