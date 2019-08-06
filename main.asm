jmp main.init

%include "common"
%include "lib/stdlib.asm"

            
data:
	.str:
		dw "Lorem ipsum dolo" ;16
		dw "r sit amet, cons" ;32
		dw "ectetur adipisci"
		dw "ng elit. Pellent" ;64
		dw "esque sit amet d"
		dw "ui id massa aliq"
		dw "uet molestie idv"
		dw "ehicula justo.  " ;128
	.ctrl_char_test:
		dw "Hello, ", 10, 9, "world!", 0
main:
	.init:
		mov sp, 0x0800
		call initDataStack
		call genOffsets
		_termMode_char
		jmp main.prog

	.prog:
		dpush data.ctrl_char_test
		call strlen
		dpop r0
		_malloc r0
		dpop r1
		_memcpy r1, data.ctrl_char_test, r0
		dpush r1
		hlt
		call prints

		jmp main.return

	.return:
		hlt

debug:
	_termMode_char

	.finish:
		hlt
		jmp .finish
	.data: