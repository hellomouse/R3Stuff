;;;
;;;   stdlib.asm
;;;   a library for interfacing with the terminal and some oth-
;;;   er utilities such as string operations.
;;;
%ifndef _STDLIB_ASM
%define _STDLIB_ASM

%include "common"
%include "datastack.asm"
%include "heap.asm"
%include "strlib.asm"
%include "rng.asm"

;notes on some instructions:
;ext n, m is shr n, m when m is in range [0, 15]
;mak n, m is shl n, m when m is in range [0, 15]

;colours
;irgb
;0001 blue
;0010 green
;0011 cyan
;0100 red
;0101 magenta
;0110 yellow
;0111 white
;1xxx intense counterpart

%define _colourAddr 0x1D00
%define _modeAddr 0x1D01
%define _kbAddr 0x1F00

;%define _doublebuffer

%ifdef _doublebuffer
backbuffer:
    org { backbuffer 256 + }
%endif

%ifdef _doublebuffer
    %define _printbuffer backbuffer
%else
    %define _printbuffer 0x1C00
%endif

bufptr:
%ifndef _doublebuffer
    dw 0x1C00
%else
    dw backbuffer
%endif

;copies the back buffer to screen
copyBuffer:
    %ifdef _doublebuffer
    push r0
    push r1
    mov r0, _printbuffer
    mov r1, 0x1C00
    .loop:
        mov [r1++], [r0++]
        cmp r1, _colourAddr
        jne .loop
    pop r1
    pop r0
    %endif
    ret

;insers a new line at the end
;slow(er) on single buffer
insertLine:
    push r0
    push r1
    push r2

    mov r1, _printbuffer
    add r1, 0x10
    mov r0, _printbuffer

    dpush [0x1D00]
    
    mov r2, 0x1D00
    mov [r2], 0

    loop r2, 0x90, .loop, .done
    .loop:
        mov [r0++], [r1++] ;4 times faster when using a backbuffr
    .done:
    
    dpop [0x1D00]

    pop r2
    pop r1
    pop r0

    ret

;prints a character
putch: ;(chr -- )
    push r0
    push r1
    dpop r1
    mov r0, [bufptr]
    mov [r0], r1
    mov r0, bufptr
    add [r0], 1
    pop r1
    pop r0
    ret

;prints a null terminated string
prints: ; (str -- )
    dpush [bufptr]
    call prints_internal
    dpop [bufptr]
    ret

;writes given string starting from ptr
prints_internal: ; (str ptr -- [new ptr])
    push r0
    push r1
    dpop r1 ;ptr
    dpop r0 ;str

    .loop:
        add [r1++], [r0++], 0
        jnz .loop
    .return:
        sub r1, 1
        dpush r1
        pop r1
        pop r0
        ret

;1CXY
;set Y to 0
;incerment X (add 0x10)
;or if double buffered: (this could apply to non double buffered aswell but since the actual screen's port is aligned to 0x10, this way is inefficent)
;ptr += ptr % 0x10
;ptr += ptr - ((ptr / 0x10) * 0x10)
;ptr += ptr - ((ptr >> 4) << 4)
;ptr += ptr - (ptr & 0xFFF0)
;ptr += ptr & 0xF
newline: ;( -- )
    push r0
    %ifndef _doublebuffer
        mov r0, bufptr
        and [r0], 0xFFF0
        add [r0], 0x10
    %else
        ;this code can be used as-is for no double buffer aswell
        ;but the above code is more optimised for that
        push r1
        push r2

        mov r1, [bufptr]
        sub r1, _printbuffer
        and r1, 15
        
        mov r2, 16
        sub r2, r1

        add [bufptr], r2

        pop r2
        pop r1
    %endif
    pop r0
    ret

%macro _termMode_char
	dpush 0
	dpush 0x0f
	dpush 1
	call initTerm
%endmacro

%macro _termMode_4bpp
    dpush 1
    dpush 0
    dpush 1
    call initTerm
%endmacro

%macro _termMode_1bpp
    dpush 2
    dpush 0
    dpush 1
    call initTerm
%endmacro

;initialises the terminal (not recommended to call directly)
;mode can be 0 (character, 16*16 colors), 1 (2*2 bitmap, 4bpp) or 2 (4*4 bitmap 1bpp)
;color is 2 irgb values, background and foreground
;reset is a boolean
initTerm: ;(mode color reset -- )
    push r0
    push r1
    push r2

    ;reset kbdin
    mov r0, 0
    mov [_kbAddr], r0

    dpop r2 ;reset
    dpop r1 ;color
    dpop r0 ;mode

    cmp r0, 2
    jna .validMode
        mov r0, 0
    .validMode:

    and r1, 0xFF
    scl r1, 8

    cmp r2, 0
    je .noReset
        or r0, 0x8000
    .noReset:

    mov [_colourAddr], r1
    mov [_modeAddr], r0

    mov r0, _printbuffer
    mov [bufptr], r0

    pop r2
    pop r1
    pop r0

    ret


;nonblocking getch, can either return 0 or chr
;won't write 0 back to keyboard buffer
getch_internal: ; ( -- chr)
    dpush [_kbAddr]
    ret

%macro _getch_internal
    dpush [_kbAddr]
%endmacro

%macro _getch_internal_mov dst
    mov dst, [_kbAddr]
%endmacro

;blocking getch, will try to get a character and return it
getch: ;( -- chr)
    push r0
    .loop:
        _getch_internal_mov r0
        cmp r0, 0
        je .loop
    dpush r0
    mov r0, 0
    mov [_kbAddr], r0
    pop r0
    ret

;gets a \n terminated string and returns a pointer
;returns null if malloc fails
gets: ;( -- str)
    push r0
    push r1 ;size counter
    push r2 ;pointer to string
    push r3 ;temp pointer to string
    mov r1, 0
    .loop:
        add r1, 1
        call getch
        call dup
        dpop r0
        cmp r0, 0xA
        jne .notNewLine
            _drop
            dpush 0
            jmp .loop_end
        .notNewLine:
        jmp .loop
    .loop_end:
    dpush r1
    call malloc
    call dup
    dpop r2
    dpop r3
    add r2, r1
    sub r2, 1
    .memwrite_loop:
            dpop [r2]
            sub r2, 1
        sub r1, 1
        jnc .memwrite_loop
    .memwrite_end:
    dpush r3
    pop r3
    pop r2
    pop r1
    pop r0
    ret


%endif