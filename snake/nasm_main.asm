[bits 16]

;Imports=================================================
	extern dump_byte
	extern dump_word
	extern arg_parse
	extern set_up
	extern clean_up
	;extern game_loop
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
	;call game_loop
	call clean_up
	.end:
	ret


SECTION .data
		newline db 13,10,'$'
		key db 0
		ExitScanCode db 0x01 ;escape pressed
		nasm_str db "Hello from NASM code!", 10, "$"
SECTION .bss