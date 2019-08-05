;;;
;;;   utils.asm
;;;   A library made to provide some basic helper functions.
;;;
%ifndef _UTILS_ASM
%define _UTILS_ASM

%include "common"

%macro pusha
	push r0
	push r1
	push r2
	push r3
	push r4
	push r5
%endmacro

%macro popa
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop r0
%endmacro

%define shl mak
%define shr ext

;%macro regn n
;	R %+ n
;%endmacro

;%macro pushn regcount
;	%assign i 0
;	%rep regcount
;		push regn(i)
;	%assign i i+1
;	%endrep
;%endmacro

;%macro popn regcount
;	%assign i regcount-1
;	%rep regcount
;		pop regn(i)
;	%assign i i-1
;	%endrep
;%endmacro

%endif