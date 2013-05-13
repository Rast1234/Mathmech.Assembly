; ball on corner

SECTION .text
	org 0x100

_main:
	
	jmp _sysexit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;FUNCTIONS;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_sysexit:
    mov ax, 0x4c00
    int 0x21
    ret


SECTION .data
		ExitScanCode db 0x01 ;escape pressed
		

SECTION .bss
		_backup resd 1
		_backup2 resd 1