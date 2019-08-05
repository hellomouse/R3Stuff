;;;
;;;   datastack.asm
;;;   A library that implements a FORTH-inspired data stack
;;;
%ifndef _DATASTACK_ASM
%define _DATASTACK_ASM

%include "common"

%define dstacksize 100
%define dp r6

%macro dpush src
	mov [--dp], src
%endmacro
%macro dpop dst
	mov dst, [dp++]
%endmacro

datastack:
    org { datastack dstacksize + } ;follow FORTH with stack practises, more it is filled, the worse the code

initDataStack:
	mov dp, datastack
	;_malloc dstacksize
	;dpop dp
	add dp, dstacksize
    ret

dup: ; (n -- n n)
	push r1
	dpop r1
	dpush r1
	dpush r1
	pop r1
	ret

swap: ; (a b -- b a)
	push r0
	push r1
	dpop r0
	dpop r1
	dpush r0
	dpush r1
	pop r1
	pop r0
	ret

drop:
	add dp, 1
	ret

%macro _drop
	add dp, 1
%endmacro

%endif