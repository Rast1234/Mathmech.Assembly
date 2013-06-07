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
;Exports=================================================
	global collision_none
	global collision_tail
	global collision_portal
	global collision_stop
	global collision_kill
	global collision_inc
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
	inc word [score]
	;AX untouched
	ret

collision_tail:
;========================================================
;	Collision with snake's tail
;
;========================================================
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
	dec word [score]
	;AX untouched
	ret

collision_inc:
;========================================================
;	Collision with death wall
;
;========================================================
	mov byte [delta], 1
	;AX untouched
	ret



SECTION .data
