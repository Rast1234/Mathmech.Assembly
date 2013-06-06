[bits 16]

;Imports=================================================
	extern mutation
;Exports=================================================
	global collision_none
	global collision_tail
	global collision_portal
	global collision_stop
	global collision_kill
;Globals=================================================
	;none

SECTION .text
collision_none:
;========================================================
;	Collision with no effect
;
;========================================================
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
	ret

collision_kill:
;========================================================
;	Collision with death wall
;
;========================================================
	ret



SECTION .data
