;a library for an overly-over-engineered tic tac toe game
;(with a large map)


;a standard map is 8 by 8, 64 bytes
mapPtr:
    dw 0x0000
winCond: ;4 symbols in a row to win
    dw 4
directionOffsets:
    dw 0xFFF8;-8 ;n  and -s
    dw 0xFFF9;-7 ;ne and -sw
    dw 1;+1 ;e  and -w
    dw 9;+9 ;se and -nw
gamestate:
    .turn:
        dw 1 ;X's turn at start
    .win:
        dw 0 ;noone won yet, 3 is for draw
    .illegal:
        dw 0 ;not an illegal board
    .moves: ;keep track of moves for replaying
        org { moves 64 + }

;quite a useless function
;just do mov [mapPtr], register
;ofc i use this because why not
setMapPtr:
    push r0
    dpop r0
    mov [mapPtr], r0
    pop r0
    ret

;ray directions' memory offsets per check:
;n  -8
;ne -7
;e  +1
;se +9
;s  +8
;sw +7
;w  -1
;nw -9

;two rays in opposite directions mustbe fired to make a proper check
; ---X--
; --X---
; [X]---
; x-----
;if we fire 2 seperate rays in opposite directions of the marked symbol without summing the rays up, X wont win in a 4-condition game
;but if the rays are summed up, X wins

checkWin: ;(ptr -- bool)
    push r0
    push r1
    push r2
    push r3

    dpop r0

    cmp [r0], 0
    je .return_fail
    
    mov r1, 0
    .loop:
        dpush r0
        dpush r1
        call dualWayRaycast
        dpop r3
        cmp r3, [winCond]
        jae .return_success

        add r1, 1
        cmp r1, 4
        jnae .loop
    jmp .return_fail
    
    .return_success:
        dpush 1
        jmp .return
    .return_fail:
        dpush 0
    .return:
        pop r3
        pop r2
        pop r1
        pop r0
        ret


;checks and marks a winner (if found)
;;;;optimisation to be made:
;use a 4 byte bitmap to keep track of checked positions
;skip the ones that are checked
;need to do:
;add a bitmap
;modify dualWayRaycast to register the checked positions
;modify checkWins or checkWin to not check checked positions
;;;;advancement to be made:
;color the winning row of symbols to green
;need to do:
;modify dualWayRaycast to set the green bit on a winning sequence

checkWins: ;( -- symbol)
    push r2
    push r1
    push r0

    mov r0, [mapPtr] ;pointer to map
    mov r1, 0        ;counter

    .loop:
        dpush r0
        call checkWin
        dpop r2
        cmp r2, 1
        je .return_success 
        add r1, 1
        cmp r1, 64
        jnae .loop
            dpush 0
            jmp .return

    .return_success:
        dpush [r0]
    .return:
        pop r2
        pop r1
        pop r0


;way integers:
;n  - s  = 0
;ne - sw = 1
;e  - w  = 2
;se - nw = 3
dualWayRaycast: ;(ptr way -- int)
    pusha

    dpop r1 ;way
    dpop r0 ;ptr

    mov r2, [mapPtr]

    mov r3, r2
    add r3, 64 ;upper bounds checking

    mov r4, 1 ;amount of symbols found

    mov r5, [r0] ;symbol to check for

    cmp r1, 3
    ja .return

    ;loop1:
        ;add directionOffsets[way] to ptr
        ;check for bounds, break if out of bounds
        ;check for symbol, add 1 to r4 if equal, break if not
    ;loop2:
        ;same as loop1 but subtract directionOffsets[way]
    ;possible optimisation: self modiying code that rewrites that add to sub

    push r0
    .loop1:
        push r1
        add r1, directionOffsets
        add r0, [r1]
        pop r1 ;add directionOffsets[way] to ptr

        cmp r0, mapPtr   ;check bounds
        jnae ..loop_break
        cmp r0, r3
        jae ..loop_break

        cmp [r0], r5     ;check symbol
        jne ..loop_break

        add r4, 1

        jmp .loop1
        ..loop_break:
        pop r0

    push r0
    .loop2:
        push r1
        add r1, directionOffsets
        sub r0, [r1] ;the only diff instr
        pop r1

        cmp r0, mapPtr   ;check bounds
        jnae ..loop_break
        cmp r0, r3
        jae ..loop_break

        cmp [r0], r5     ;check symbol
        jne ..loop_break

        add r4, 1

        jmp .loop2
        ..loop_break:
        pop r0

    .return:
        dpush r4
        popa
        ret

printboard_direct: ;(bufptr -- )
    push r0
    push r1
    push r2 
    push r3
    push r4

    dpop r0
    sub r0, 1
    mov r1, [mapPtr]

    mov r2, 0
    .loop_row:
        mov r3, 0
        ..loop_col:
            add r0, 1

            mov r4, [r1++] ;determine char
            cmp r4, 1
            je ...printx ;print X
            cmp r4, 2
            je ...printo ;print O
                ;print empty
                mov r4, '-'
                jmp ...print_determine_end
            ...printx:
                mov r4, 'X'
                jmp ...print_determine_end
            ...printo:
                mov r4, 'O'
            ...print_determine_end:

            mov [r0], r4 ;print

            add r3, 1 ;loop
            cmp r3, 8
            jnae ..loop_col
        add r0, 0x10 ;newline
        sub r0, 0x8
        add r2, 1 ;condition checks
        cmp r2, 8
        jnae .loop_row
    
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

printboard_stdlib: ;( -- )
    ret

resetBoard: ;( -- )
    push r0
    push r1
    mov r0, [mapPtr]
    mov r1, 0
    .loop:
        mov [r0++], 0
        add r1, 1
        cmp r1, 64
        jnae .loop
    pop r1
    pop r0
    ret

resetGame: ;( -- )
    push r0
    push r1

    mov r0, gamestate.turn
    mov [r0], 1
    mov r0, gamestate.win
    mov [r0], 0
    mov r0, gamestate.illegal
    mov [r0], 0

    mov r0, gamestate.moves
    mov r1, 0
    .loop_moves:
        mov [r0++], 0
        add r1, 1
        cmp r1, 64
        jnae .loop_moves

    call resetBoard

    pop r1
    pop r0

    ret

XYtoPtr: ;(x y -- ptr)
    push r0
    push r1

    ;return mapPtr + X + (Y * 8)

    dpop r1
    dpop r0

    add r0, [mapPtr]
    scl r1, 3 ;multiply by 8
    add r0, r1

    dpush r0

    pop r1
    pop r0
    ret

;replay format:
;
replay: ;(replay -- )
    dpop r0
    call resetBoard

    mov r1, 0
    .loop:
        call printboard_direct
