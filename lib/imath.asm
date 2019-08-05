;;;
;;;   imath.asm
;;;   integer math library
;;;
;;;   depends on:
;;;    - datastack
;;;

%define imul imul_single_peasent
%macro imul src dst
    dpush src
    spush dst
    call imul
    dpop src
%endmacro

imul_single_addition: ;(a b -- c) internal
    push r0
    push r1

    dpop r0
    dpop r1

    .loop:
        cmp r1, 0
        jz .return
            add r0, r10
        sub r1, 1
        jmp .loop
    .return:
        dpush r1
        pop r1
        pop r0
        ret
        
imul_single_peasent: ;(a b -- c) internal
    pusha
    dpop r1
    dpop r0
    mov r2, 0
    mov r3, 0

    .loop:
        mov r4, r1
        and r4, 1
        cmp r4, 0
        je .not_high
            ;add r0 << r3 to r2
            shl r4, r0, r3
            add r2, r4
        .not_high:
        
        shr r1, 1
        cmp r1, 0
        je .return

        add r3, 1
        cmp r3, 16
        jnae .loop
    
    .return:
    dpush r2
    popa
    ret