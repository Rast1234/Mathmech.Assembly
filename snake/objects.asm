[bits 16]

;Imports=================================================
	extern collision_none
	extern collision_tail
;Exports=================================================
	;none
;Globals=================================================
	;none

SECTION .text
get_object_type:
;========================================================
;	Determine object type from byte
;
;Arguments:
;		BL: object number (from game field)
;
;Returns:
;		BX: object descriptor address
;========================================================
	;0 -> empty
	;1 -> head
	;2 -> tail
	; ...
	push si
	mov si, objects
	mov bh, 0
	shl bx, 1  ; BL*2
	add si, bx
	mov bx, [si]
	pop si
	ret

SECTION .data
;Named objects, in format:
;	BYTE	ttl (living time in game ticks, 0 is infinity)
;	BYTE	sprites (number of frames, minimum 1)
;	WORD	score (cost earned by player, SIGNED)
;	WORD	collision handler (near ptr to function)
;	WORD	pixmap pointer (near ptr to pixel array, = 0)
;	ASCIZ	name (also a bitmap filename)

objects ;start descriptor table

	empty	db 0, 1
			dw 0, collision_none, 0
			db 'NULL\0'

	head	db 0, 1
			dw 0, collision_none, 0
			db 'head\0'

	tail	db 0, 1
			dw 0, collision_tail, 0
			db 'tail\0'

;Object lookup table
lookup dw empty, head, tail
