;;;
;;;   mgfx.asm
;;;   A monochrome graphics library.
;;;
;;;   depends on:
;;;    - common
;;;    - utils
;;;    - datastack
;;;

;a byte in framebuffer corresponds to a 4 by 4 bitmap inside the terminal
;a segment is just a byte containing bitmap data
;a sprite is made of 4 segments and is 16 by 16
;sprites must be aligned to segment boundaries so the possible coordinate space is 16*16
;sprites are kept track of and might get rendered on top of eachother
;segments are not kept track of and can be directly rendered onto the screen
;optionally, you can store a segment in the segment store for later rendering

;segment bit layout:
;
;FEDCBA9876543210 becomes
;0123
;4567
;89AB
;CDEF

;sprite format:
;1 byte flags&pos
;
;4 bytes segment info
;or
;1 byte segment indices
;
;heap is used to store sprites and pointers are stored
;indiced sprites can only access the first 16 of 32 segments
;
;flags&pos byte:
;sv..llllxxxxyyyy
;s hardcoded segments
;v visible
;l layer
;x x coords
;y y coords

brokenSprite:
    dw 0b1100000000000001 ;hardcoded, visible, layer 0, pos(0,0)
    ;dw 0b1111011100011111 ;E
    ;dw 0b0111100101111001 ;R
    ;dw 0b0110100110010110 ;O
    ;dw 0b0111100101111001 ;R
    dw 0b0001000100011111
    dw 0b1000100010001111
    dw 0b1111000100010001
    dw 0b1111100010001000

spritePointers:
    org { spritePointers 16 + }

segmentStorePtr: ;segments will be stored in the heap
    dw 0

;initialises the library
initmgfx: ;( -- )
    _malloc 32
    dpop [segmentStorePtr]
    ret

;gets a segment from segment store
getsegment: ;(index -- segment)
    push r0
    mov r0, [segmentStorePtr]
    add r0, [dp]
    _drop
    dpush [r0]
    pop r0
    ret

;renders a segment to a given position
rendersegment: ;(segment x y -- )
    push r0
    push r1
    push r2

    dpop r1 ;y
    dpop r0 ;x

    cmp r0, 16
        jae .return
    cmp r1, 16
        jae .return

    shl r1, 4
    add r0, r1
    add r0, [currentBufPtr]
    dpop r1 ;segment
    mov [r0], r1

    .return:
        pop r2
        pop r1
        pop r0

        ret

getsprite: ;(idx -- ptr)
    push r0
    
    mov r0, spritePointers
    add r0, [dp]
    _drop

    cmp r0, 0
    je .spriteExists
        dpush brokenSprite
        jmp .return
    .spriteExists:
        dpush [r0]
    .return:
        pop r0
        ret


rendersprite: ;(ptr -- )
    pusha

    dpop r0
    
    mov r1, [r0]
    shr r1, 15
    cmp r1, 1
    je .segments_hardcoded
    ;segments are not hardcoded (are indexed)
        _malloc 2
        dpop r2 ;r2 is the pointer, need to fill it in

        ;mov [r2++], getsegment(r0[1]>>0,4,8,12)
        add r0, 1
        dpush [r0]
        sub r0, 1

        ;9.25 ticks rolled
        ;6 ticks unrolled
        mov r3, 0
        .segment_loop:
            call dup
            shr [dp], r3
            and [dp], 0xF
            call getsegment
            mov [r2++], [dp]
            _drop
            add r3, 4
            cmp r3, 12
            jna .segment_loop

        jmp .render
    .segments_hardcoded:
        mov r2, r0
        add r2, 1; r2 is the pointer to segment array
    .render:
        ;use r2's array to render
        mov r1, [r0]
        and r1, 0xF
        mov r4, r1 ;x

        mov r1, [r0]
        shr r1, 4
        and r1, 0xF
        mov r3, r1 ;y

        dpush [r2++]
        dpush r3
        dpush r4
        call rendersegment
        add r3, 1

        dpush [r2++]
        dpush r3
        dpush r4
        call rendersegment
        add r4, 1
        sub r3, 1

        dpush [r2++]
        dpush r3
        dpush r4
        call rendersegment
        add r3, 1

        dpush [r2++]
        dpush r3
        dpush r4
        call rendersegment

    .return:
        popa
        ret


renderBrokenSprite: ;( -- )
    dpush brokenSprite
    call rendersprite
    ret