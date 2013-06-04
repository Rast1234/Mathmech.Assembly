[bits 16]

;Imports=================================================
	extern dump_byte
	extern dump_word
	extern arg_parse
	extern set_up
	extern clean_up
	extern init_config
	extern game
	extern print
	extern init_objects
	extern destroy_objects
;Exports=================================================
	global nasm_main
;Globals=================================================
	;none

SECTION .text
nasm_main:
;========================================================
;	Main runner of snake
;		reads cmd line, sets video mode,
;		interrupt handlers, timers etc.
;
;Arguments:
;		none
;
;Returns:
;		none
;========================================================
	call arg_parse
	cmp ax, 1
	je nasm_main.end

	call set_up
	call init_config
	call init_objects
	call game
	call destroy_objects
	call clean_up
	.end:
	ret


SECTION .data
		newline db 13,10,'$'
		key db 0
		ExitScanCode db 0x01 ;escape pressed
		nasm_str db "Hello from NASM code!", 10, "$"
