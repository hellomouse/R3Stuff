;;;
;;;   strlib.asm
;;;   a library for manipulating strings
;;;
%ifndef _STRLIB_ASM
%define _STRLIB_ASM

%include "common"
%include "datastack.asm"
%include "heap.asm"

%macro _memcpy dst, src, length
    dpush dst
    dpush src
    dpush length
    call memcpy
%endmacro
memcpy: ;( dst src length -- )
	push r0 ;dst
	push r1 ;src
	push r2 ;length
	
	dpop r2
	dpop r1
	dpop r0

	cmp r2, 0 ;we dont wanna copy a byte if len = 0
	je .return

	;sub r2, 1 ;we dont wanna copy an extra byte at the end
	; ^ for no-loop-control implementation

	push r3
	loop r3, r2, .loop, .return
	pop r3

	.loop:
		mov [r0++], [r1++]
		;sub r2, 1
		;jnc .loop
	.return:
	
	pop r2
	pop r1
	pop r0
	ret

%macro _atoi_binary str
    dpush str
    call atoi_binary
%endmacro
;converts a binary string to an integer
atoi_binary: ;(str -- int)
    push r0
    push r1
    dpop r0
    mov r1, 0

    .loop:
        scl r1, 1
        push r0
        mov r0, [r0]
        sub r0, '0'
        add r1, r0
        pop r0

        add r0, 1
        cmp [r0], 0
        jne .loop

    .return:
        dpush r1
        pop r1
        pop r0
        ret

%macro _itoa_hex int
    dpush int
    call itoa_hex
%endmacro
;converts an integer to a hex string padded with zeroes
itoa_hex: ;(int -- str)
    push r0
    push r1
    push r2

    dpop r0
    
    _malloc 5
    dpop r3
    add r3, 4


    mov r2, 12
    .loop:
        shr r1, r0, r2
        and r1, 0xF
        add r1, .lookup

        mov [r3++], [r1]

        sub r2, 4
        jnc .loop
    

    mov [r3], 0 ;null terminate
    sub r3, 4
    dpush r3

    pop r2
    pop r1
    pop r0

    ret

    .lookup:
        dw "0123456789ABCDEF"

%macro _streq stra, strb
    dpush stra
    dpush strb
    call _streq
%endmacro
;compares 2 strings' contents, returns 1 if equal, 0 if not equal
;yes, this is not the same as c strcmp, will fix later //changed the fn name accordingly
;strcmp: ;(stra strb -- bool)
streq: ;(stra strb -- bool)
    push r0
    push r1
    push r2
    push r3
    dpop r1 ;b
    dpop r0 ;a

    ;check size first, could speed stuff up a lot
    dpush r0
    call strlen
    dpop r2
    dpush r1
    call strlen
    dpop r3
    cmp r2, r3
    jne .notEqual

    .loop:
        mov r2, 0
        mov r3, 0
        cmp [r0], 0
        jnz .r0NotZero
            mov r2, 1
        .r0NotZero:
        cmp [r1], 0
        jnz .r1NotZero
            mov r3, 1
        .r1NotZero:

        ;if r2 xor r3 == true then return false (one of the strings ended, length diff, redundant)
        ;if r0 != r1 then return false
        ;if ~r2 and ~r3 == true then return true (string end, no differences have been found)

        push r2
        push r3
        xor r2, r3
        cmp r2, 1
        pop r3
        pop r2
        je .notEqual

        xor r2, 1 ;same as NOT (boolean)
        xor r3, 1
        and r2, r3
        cmp r2, 1
        je .equal

        mov r2, [r0++] ;compare character
        mov r3, [r1++]
        cmp r2, r3
        jne .notEqual

        jmp .loop
    .equal:
        dpush 1
        jmp .return
    .notEqual:
        dpush 0
    .return:
        pop r3
        pop r2
        pop r1
        pop r0
        ret

%macro _memset ptr, val, len
    dpush ptr
    dpush val
    dpush len
    call memset
%endmacro
;sets a chunk of memory to a byte
memset: ;(ptr val len -- )
    push r0
    push r1
    push r2
    push r3

    dpop r2 ;len
    dpop r1 ;val
    dpop r0 ;ptr

    loop r3, r2, .loop, .done
    .loop:
        mov [r0++], r1
    .done:

    pop r3
    pop r2
    pop r1
    pop r0

%macro _strlen str
    dpush str
    call _strlen
%endmacro
;gets the length (incl. null) of a string
strlen: ; (str -- length)
    push r0
    push r1
    mov r1, 0
    dpop r0
    .loop:
        add r1, 1
        cmp [r0++], 0
        jnz .loop
    dpush r1
    pop r1
    pop r0
    ret

;copies contents of strs into strd
;use strncpy instead
strcpy: ;(strd strs -- )
    push r0
    push r1

    dpop r1
    dpop r0

    ;check if r1 is just a zero
    cmp [r1], 0
    je .return

    .loop:
        mov [r0++], [r1++]
        cmp [r1], 0
        jne .loop
    mov [r0], 0

    .return:
        pop r1
        pop r0
        ret

;copies contents of strs into strd without exceeding len
strncpy: ;(strd strs len -- )
    push r0
    push r1
    push r2
    push r3
    push r4

    dpop r2 ;len
    dpop r1 ;strs
    dpop r0 ;strd
    mov r4, 0

    loop r3, r2, .loop, .done
    .loop:

        mov [r0++], [r1++]

        cmp [r1], 0
        jne ..not_zero
            mov r3, lc
            mov [r3], 1 ;copy one last byte to null terminate
            mov r4, 1   ;mark r3 with 1 to indicate loop ended due to a zero
        ..not_zero:
    .done:

    cmp r4, 1
    jne .terminated
        sub r1, 1
        mov [r1], 0 ;null term
    .terminated:

    pop r4
    pop r3
    pop r2
    pop r1
    pop r0

%endif