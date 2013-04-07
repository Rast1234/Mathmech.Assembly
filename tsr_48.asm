;This code is from internets
;original page can be found at:
; http://www.hugi.scene.org/online/coding/hugi%2011%20-%20xnumcaps.htm

.MODEL TINY
.CODE
ORG 100h
start_of_program:
jmp short transient
int9proc:  ;This is the resident handler for INT 9
push ds    ;Save all registers that are used
push ax
pushf
xor ax,ax
mov ds,ax  ;0 => DS
and byte ptr ds:[417h],(0ffh-60h)  ;Clear CapsLock and Numlock
                                   ;status bits at 0:417h (i.e. 40:17h)
popf
pop ax
pop ds
db 0eah                            ;far jump to the far pointer in oldint9h
oldint9 dw 0,0ffffh                ;filled in by the program before use
                                   ;(or your computer will reboot!!)

transient:
mov ax,3000h
int 21h                            ;get dos version
cmp al,2                           ;DOS 2+ ???
jae dos_version_ok                 ;yes - continue
int 20h                            ;this should terminate the program
dos_version_ok:
cmp sp,offset end_of_program+100h  ;is there enough stack?
ja enough_stack
mov dx,offset error_text
mov ah,9
int 21h                            ;show an error message
mov ax,4c01h
int 21h                            ;terminate with exit code 1
enough_stack:
mov dx,offset copyright
mov ah,9
int 21h                            ;display the copyright
mov ax,2523h
mov byte ptr ds:[100h],0cfh        ;write an IRET to a now unused byte
mov dx,100h
int 21h                            ;and set the vector of Interrupt 23h
                                   ;(Dos-Ctrl-C-Interrupt) to it
mov ax,3509h
int 21h                            ;get vector of hardware keyboard
                                   ;interrupt 9...
mov word ptr ds:[oldint9],bx       ;...and save it...
mov word ptr ds:[oldint9+2],es     ;...to oldint9
mov ax,ds:[2ch]                    ;segment of Dos environment block
or ax,ax                           ;is it zero?
jz no_environment
mov es,ax
mov ah,49h                         ;if it is not...
int 21h                            ;...then free this memory block...
mov word ptr ds:[2ch],0            ;...and set the addy to 0
no_environment:
mov bx,(offset transient)-(offset int9proc)  ;the size required
                                        ;for the resident program (Bytes)
mov si,bx
add bx,15                               ;add 15 bytes because Dos can only
                                        ;allocate paragraphs
                                        ;(blocks of 16 bytes)
mov cl,4
shr bx,cl                               ;number of paragraphs required
push bx
mov ah,48h
int 21h                                 ;allocate memory for TSR
jc mem_error                            ;if that is not available then
                                        ;just make it resident the
                                        ;"normal" way!

mov es,ax                               ;the segment address
                                        ;of the TSR block



; *** This block is only necessary because MEM            ***
; *** sometimes did not get the name of the TSR right.    ***
; *** Therefore the TSR block was filled with zero bytes. ***
xor ax,ax
mov di,ax
pop cx       ;number of allocated paragraphs
shl cx,1
shl cx,1
shl cx,1     ;number of words (i.e. bytes*2)
cld
rep stosw    ;fill the TSR block with zero

xor di,di
mov cx,si    ;Length of the TSR routine
mov si,offset int9proc
rep movsb    ;write the TSR routine to the TSR block
push es
pop ds
mov ax,ds
dec ax
mov es,ax     ;Address of MCB of the TSR block
mov es:[1],ds ;"owner" of the TSR block=the TSR block itself

mov ax,2509h
xor dx,dx
int 21h       ;set INT 9 vector to our resident program block

mov ax,cs
dec ax
mov ds,ax     ;the segment of the MCB
mov si,5
mov di,si
mov cx,11
rep movsb     ;copy last 11 bytes (including the name of the TSR for Dos 4+)
              ;from the transient code segment MCB to the MCB of the TSR
mov ax,4c00h
int 21h       ;and terminate the transient program with Exit code 0

error_text db 7,'XNUMCAPS aborted!'
             db ' Insufficient memory!',13,10,'$'
mem_error:
mov ax,2509h
mov dx,offset int9proc
int 21h                 ;set interrupt 9 vector to handler in TSR
mov dx,offset transient ;number of bytes of TSR
int 27h                 ;make program resident
copyright db 'XNUMCAPS - freeware TSR to switch off '
          db 'CapsLock and NumLock permanently.',13,10,13,10
          db '(C) Robert Flogaus-Faust, 1998',13,10,13,10
          db 'This program must not be distributed'
          db ' without the original source code!',13,10,13,10
          db       '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
          db 13,10,'!USE IS ENTIRELY AT YOUR OWN RISK!',13,10
          db       '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!',13,10,13,10,'$'

end_of_program:
END start_of_program
END.