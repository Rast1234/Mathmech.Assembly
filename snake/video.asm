[bits 16]

;Imports=================================================
	;none
;Exports=================================================
	global save_mode
	global set_mode
;Globals=================================================
	common screen 4800
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
