;;;
;;;   rng.asm
;;;   a random number generator
;;;
%ifndef _RNG_ASM
%define _RNG_ASM

rngstate:
    dw 0xDEAD ;16
    dw 0xBEEF ;32
    ;dw 0x00BA
    ;dw 0xB10C ;64
    ;dw 0x8BAD
    ;dw 0xF00D
    ;dw 0xDEAD
    ;dw 0xC0DE ;128

rng16:
    ;state ^= state << 7
    ;state ^= state >> 9
    ;state ^= state << 8

    push r0
    push r1

    mov r0, [rngstate]

    shl r1, r0, 7
    xor r0, r1

    shr r1, r0, 9
    xor r0, r1

    shl r1, r0, 8
    xor r0, r1

    mov [rngstate], r0
    dpush r0

    pop r1
    pop r0

    ret

;7.142857% slower than rng16
rng32:
    ;state is uint32_t
	;state ^= state << 13;
	;state ^= state >> 17;
	;state ^= state << 5;
    push r0
    push r1
    push r2
    push r3

    mov r0, [rngstate]
    mov r1, rngstate
    add r1, 1
    mov r1, [r1]

    shl r2, r0, 13
    scl r3, r1, 13
    xor r1, r3
    xor r0, r2

    shr r2, r0, 17
    scr r3, r1, 17
    xor r1, r3
    xor r0, r2

    shl r2, r0, 5
    scl r3, r1, 5
    xor r1, r3
    xor r0, r2

    mov r2, rngstate
    mov [r2++], r0
    mov [r2++], r1

    dpush r1
    dpush r0

    pop r3
    pop r2
    pop r1
    pop r0
    
    ret

rng64:
    ;state is uint64_t
	;state ^= state << 13;
	;state ^= state >> 7;
	;state ^= state << 17;
    ret

rng128:
    ;state is uint32_t*
    ;t = state[3]
    ;s = state[0]
    ;state[3] = state[2]
    ;state[2] = state[1]
    ;state[1] = s
    ;t ^= t << 11
    ;t ^= t >> 8
    ;retuirn state[0] = t ^ s ^ (s >> 19)
    dpush 0 ;this wont be implemented for a while
    ret

%endif