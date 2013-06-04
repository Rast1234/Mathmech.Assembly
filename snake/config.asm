[bits 16]
%define screen_size 80*60
;Imports=================================================
	extern dump_word
;Exports=================================================
	global key_exit
	global key_pause
	global init_config
;Globals=================================================
	common screen screen_size
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
	push bx
	push cx
	mov [key], byte 0x0
	mov cx, screen_size
	mov bx, screen
	.fill:
		mov [bx], word 0
		add bx, 2
		loop init_config.fill
	pop cx
	pop bx
	ret

SECTION .data
	key_exit	db 0x01	; ESC scancode
	key_pause	db 0x4D	; P