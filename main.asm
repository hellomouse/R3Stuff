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
main:
	.init:
		mov sp, 0x0800
		call initDataStack
		call genOffsets
		_termMode_char
		jmp main.prog

	.prog:

		_memcpy _printbuffer, data.str, 128
		call copyBuffer
		hlt
		call insertLine
		call copyBuffer

		jmp main.return

	.return:
		hlt

debug:
	_termMode_char

	.finish:
		hlt
		jmp .finish
	.data: