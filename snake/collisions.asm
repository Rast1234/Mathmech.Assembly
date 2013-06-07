[bits 16]
%define cell_size 16
%define act_exit 3
%define act_none 0
%define mutation_mask_cross_transparent	0b00000001
%define mutation_mask_godmode			0b00000010
%define mutation_mask_noclip			0b00000100
%define dir_stop 0
%define dir_up 1
%define dir_down 2
%define dir_left 3
%define dir_right 4
;Imports=================================================
	extern mutation
	extern direction
	extern snake
	extern game_over
	extern goodfood
	extern badfood
	extern take_object
	extern get_object
	extern head
	extern tail
	extern speaker_on
	extern speaker_off
;Exports=================================================
	global collision_none
	global collision_tail
	global collision_portal
	global collision_stop
	global collision_kill
	global collision_inc
	global collision_dec
	global collision_bounce
;Globals=================================================
	common screen 2000
	common key 1
	common paused 1
	common length 2
	common score 2
	common delta 1

SECTION .text
;========================================================
;
;	REMEMBER!!!!
;	
;	Collision handler recieves old snake's head
;	position in [snake] and desired head position
;	in AX (also a object's self position).
;
;	It has to return new head's position in AX.
;
;========================================================
collision_none:
;========================================================
;	Collision with no effect
;
;========================================================
	;inc word [score]
	;AX untouched
	ret

collision_tail:
;========================================================
;	Collision with snake's tail
;
;========================================================
	push bx
	mov bl, [mutation]
	and bl, byte mutation_mask_cross_transparent
	cmp bl, 0
	je collision_tail.end
	;else behave like a bad wall
	call collision_kill
	.end:
	push ax
	mov ax, 0x4242
	call speaker_on
	pop ax
	pop bx
	ret

collision_portal:
;========================================================
;	Collision with magic portal
;
;========================================================
	ret

collision_stop:
;========================================================
;	Collision with simple wall
;
;========================================================
	mov ax, [snake]
	mov [direction], byte dir_stop
	ret

collision_kill:
;========================================================
;	Collision with death wall
;
;========================================================
	;dec word [score]
	mov [game_over], byte 1
	inc word [badfood]
	;AX untouched
	ret

collision_inc:
;========================================================
;	Collision with good food
;
;========================================================
	mov byte [delta], 1
	inc word [goodfood]
	;AX untouched
	push ax
	mov ax, 0x0510
	call speaker_on
	pop ax
	ret


collision_dec:
;========================================================
;	Collision with bad food
;
;========================================================
	mov byte [delta], 2
	inc word [badfood]
	;AX untouched
	push ax
	mov ax, 0x2020
	call speaker_on
	pop ax
	ret

collision_bounce:
;========================================================
;	Collision with ricochet wall
;
;========================================================
	mov bx, [snake] ; current snake pos x : y
	
	;try go in opposite direction.
	;if these's tail - set ax to [snake] (current position)

	mov bx, [snake]
	cmp [direction], byte dir_stop
	je collision_bounce.end
	cmp [direction], byte dir_up
	je collision_bounce.move_up
	cmp [direction], byte dir_down
	je collision_bounce.move_down
	cmp [direction], byte dir_left
	je collision_bounce.move_left
	cmp [direction], byte dir_right
	je collision_bounce.move_right
	jmp collision_bounce.end

	mov dx, ax ;store
	.move_up:
		; try go down
		mov ax, [snake]
		inc al
		call take_object
		call get_object
		cmp bx, tail
		je collision_bounce.better_stop
		mov ax, [snake]
		inc al
		mov [direction], byte dir_down
		jmp collision_bounce.end
	.move_down:
		; try go up
		mov ax, [snake]
		dec al
		call take_object
		call get_object
		cmp bx, tail
		je collision_bounce.better_stop
		mov ax, [snake]
		dec al
		mov [direction], byte dir_up
		jmp collision_bounce.end
	.move_left:
		; try go right
		mov ax, [snake]
		inc ah
		call take_object
		call get_object
		cmp bx, tail
		je collision_bounce.better_stop
		mov ax, [snake]
		inc ah
		mov [direction], byte dir_right
		jmp collision_bounce.end
	.move_right:
		; try go left
		mov ax, [snake]
		dec ah
		call take_object
		call get_object
		cmp bx, tail
		je collision_bounce.better_stop
		mov ax, [snake]
		dec ah
		mov [direction], byte dir_left
		jmp collision_bounce.end
	.better_stop:
		mov ax, [snake]
	.end:
	push ax
	mov ax, 0x0400
	call speaker_on
	pop ax
	ret


SECTION .data
