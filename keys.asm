;displays keypress info:
;
;<SCANCODE> <ASCII code> <Glyph>
;
;exit on ESC
;uses int 0x16
;handles key combinations

SECTION .text
	org 0x100

_main:
	mov ah, 0x09
	mov dx, statrline
	int 0x21
	mov cx, 23
	_infinite:

		;mov ah, 0x11 ;extended keyb status
		mov ah, 0x10 ;keyb read
		int 0x16
		;ZF = 0 if character available
		;jz _infinite ;if 1, loop
			;okay, keyboard stuff available in AX
			;AL = ascii / AH = SCANCODE
			mov bx, ax ;save it
			mov ah, 0x12 ;extended shift status
			int 0x16
			;AL = Insert-Caps-NumLk-ScrLck-Alt-Ctrl-Lshift-Rshift
			;AH = SysRq-CapsLk-NumLk-ScrLk-RAlt-RCtrl-LAlt-LCtrl
			;call dump_word

			cmp cx, 0
			je _cx_0
			jne _cx_ok

			_cx_0:
				mov ah, 0x09
				mov dx, statrline
				int 0x21
				mov cx, 23
				jmp _work
			_cx_ok:

				dec cx
				jmp _work
			_work:

			
			call print_stuff
			call print_shifts
			call print_newline

			cmp bl, 0x1B ;escape
			je _end
		jmp _infinite
	_end:
	mov ah, 0x09
	mov dx, endline
	int 0x21
    jmp _sysexit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
__help:
    mov ah, 0x9
    mov dx, symbols
    int 0x21
    jmp _sysexit

print_stuff: ; prnit Scancode, ASCII code and symbol
		; BX = to print scancode:ascii
	push ax
	push dx
	mov ah, 0x09
	mov dx, scancode
	int 0x21
	mov al, bh
	call dump_byte
	mov ah, 0x09
	mov dx, asciicode
	int 0x21
	mov al, bl
	call dump_byte
	mov ah, 0x09
	;#############################################
		;filter non-printing characters
		cmp al, 0
		je _replace
		cmp al, 07
		je _replace
		cmp al, 08
		je _replace
		cmp al, 09
		je _replace
		cmp al, 10
		je _replace
		cmp al, 13
		je _replace
		cmp al, 0x1B ;ESCape
		je _replace
		jmp _char_ok

		_replace:
			mov al, 0x20 ;replace with space
		_char_ok:
	mov dx, character
	int 0x21
	;=============================
	mov ah, 0x02
	mov dl, al
	int 0x21
	; mov ah, 0x03
	; xor bh, bh
	; int 0x10
		;;ch:cl dh:dl cursor
	; mov ah, 0x09
	; mov cx, 1
	; int 0x10
	; inc dl
	; mov ah, 0x02
	; int 0x10
	;=============================
	mov ah, 0x09
	mov dx, character_after
	int 0x21
	pop dx
	pop ax
	ret

print_shifts: ;print extended info
	;AL = Insert-Caps-NumLk-ScrLck-Alt-Ctrl-Lshift-Rshift
	;AH = SysRq-CapsLk-NumLk-ScrLk-RAlt-RCtrl-LAlt-LCtrl
	push ax
	push bx
	push cx
	push dx
	push ax
	mov cx, 8
	mov dl, al ;save
	call _magic
	pop ax
	mov dl, ah
	call _magic
	pop dx
	pop cx
	pop bx
	pop ax
	ret
_magic:
	push ax
	push dx
		;DL - to parse
	mov bh, dl
	mov cx, 8
	mov bl, 0b10000000
	_ololoop:
	mov al, bh
	and al, bl
	cmp al, bl
	je print_pr
	jne print_npr
	print_pr:
		mov ah, 0x09
		mov dx, present
		int 0x21
		jmp endloop
	print_npr:
		mov ah, 0x09
		mov dx, not_present
		int 0x21
		jmp endloop
	endloop:
		shr bl, 1
		loop _ololoop
	pop ax
	pop dx
	ret
print_newline:
	push ax
	push dx
	mov ah, 0x09
	mov dx, newline
	int 0x21
	pop dx
	pop ax
	ret

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



_sysexit:
    mov ax, 0x4c00
    int 0x21
    ret


SECTION .data
        symbols db '0123456789ABCDEF$'
        newline db 13,10,'$'
        present db ' + ',179,'$'
        not_present db '   ',179,'$'
        statrline db 213,205,205,205,205,209 ;'scancode'
        			db 205,205,205,205,209,
        			db 205,205,205,203,

        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,203,
        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,209,
        			db 205,205,205,184,

        			db 13,10
        			;next line
        			db 179,'SCAN',179,'ASCI',179,'CHR',186
        			db 'Ins Cps Nlk Scr Alt Ctr Lsh Rsh ' 
        			db 'Srq Cps Nlk Scr AlR CtR AlL CtL',179
        			db 13,10,'$'
        endline db 212,205,205,205,205,207 ;'scancode'
        			db 205,205,205,205,207,
        			db 205,205,205,202
        			

        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,207,
        			db 205,205,205,190,

        			db 13,10,'$'


        scancode db 179,' $'
        asciicode db ' ',179,' $'
        character db ' ',179,' $'
        character_after db 32,186,'$'
        ;AL = Insert-Caps-NumLk-ScrLck-Alt-Ctrl-Lshift-Rshift
		;AH = SysRq-CapsLk-NumLk-ScrLk-RAlt-RCtrl-LAlt-LCtrl
		shifts_al db "In Ca Nu Sc Al Ct Ls Rr "
		shifts_ah db "Sy Ca Nu Sc Ra Rc La Lc "
