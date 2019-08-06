;;;
;;;   heap.asm
;;;   A library that provides dynamic memory allocation.
;;;
%ifndef _HEAP_ASM
%define _HEAP_ASM

%include "common"
%include "utils.asm"
%include "datastack.asm"

;1024 bytes with 32 objects max (32 bytes (max) per object at 32 objects)
;%define heapsize 0x400
;%define maxentries 32

;768 bytes, 24 objects
;%define heapsize 0x300
;%define maxentries 24

;512 bytes, 16 objects
%define heapsize 0x200
%define maxentries 16


entryoffsets:
	org { entryoffsets maxentries + }
entrysizes:
	org { entrysizes maxentries + }
heap:
	org { heap heapsize + }

;generates offsets for the entryoffsets array
genOffsets: ;( -- )
	push r0
    push r1

	mov r0, 0
	.loop:
			mov r1, r0
			add r1, entryoffsets
			mov [r1], 0xFFFF
		add r0, 1
		cmp r0, maxentries
		jnae .loop
	.return:
    pop r1
	pop r0

	ret

;gets an entry index at heap offset or gives 0xFFFF if no entry is found
getEntryAtOffset: ; (offset -- entry#)
	push r0
	push r1
	push r2
	
	dpop r1
	mov r0, 0
	.loop:
			mov r2, r0
			add r2, entryoffsets
			cmp [r2], r1
			je .return_success 
		add r0, 1
		cmp r0, maxentries
		jnae .loop
	.return_fail:
		dpush 0xFFFF
		jmp .return
	.return_success:
		dpush r0
	.return:
		pop r2
		pop r1
		pop r0
		ret

;gets the first empty (offset == 0xFFFF) entry index
getFirstEmptyEntry: ; ( -- entry#)
	push r0
	push r1
	mov r0, 0
	.loop:
			mov r1, r0
			add r1, entryoffsets
			cmp [r1], 0xFFFF
			je .return_success
		add r0, 1
		cmp r0, maxentries
		jnae .loop
	.return_fail:
		dpush 0xFFFF
		jmp .return
	.return_success:
		dpush r0
	.return:
		pop r1
		pop r0
		ret

;;will be removed
;returns if an empty entry exists
emptyEntryExists: ;( -- bool)
	push r0
	call getFirstEmptyEntry
	dpop r0
	cmp r0, 0xFFFF
	je .return_fail
		dpush 1
		pop r0
		ret
	.return_fail:
		dpush 0
		pop r0
		ret

%macro _malloc size
	dpush size
	call malloc
%endmacro
;allocates a region in memory with a given size
;if no free space with size could be found, returns null
;if no emtpy entry slots exists, returns null
;if an empty space with size is found, returns the pointer to the start of that space
;uses first-fit allocation
malloc: ;(size -- ptr)
	pusha

	call getFirstEmptyEntry
	dpop r0
	cmp r0, 0xFFFF
	je .return_null

	;r0 -> requested size (always)
	;r1 -> current counted size (always)
	;r2 -> address being worked on (always)
	;r3 -> loop counter (always)
	;r4 -> temp register
	;r5
	dpop r0 ;get requested size
	mov r1, 0
	mov r2, 0

	;pseudo:
	;loop:
	;	check if entry exists at location:
	;		add the entry's size - 1 to loop counter
	;		set found address to nullptr
	;		continue
	;	check if we are *not* working on an address:
	;		set found address to the loop counter + heap
	;	
	;	add 1 to size counter
	;
	;	check if size counter >= requested size:
	;		dpush found address
	;		find the first free entry slot
	;			make it's size requested size
	;			make its location found address
	;		return

	mov r3, 0
	.loop:
		dpush r3
		call getEntryAtOffset
		cmp [dp], 0xFFFF
		je ..noEntryAtOffset
			add [dp], entrysizes
			add r3, [dp]
			sub r3, 1
			_drop
			jmp ..loop_continue
		..noEntryAtOffset:
		_drop

		cmp r2, 0
		jne ..workingOnAddress
			mov r2, r3
			add r2, heap
		..workingOnAddress:

		add r1, 1

		cmp r1, r0
		jnae ..sizeNotMet
			dpush r2

			call getFirstEmptyEntry ; (-- addr entry#)

			mov r4, entryoffsets
			add r4, [dp]            ; still (-- addr entry#)
			mov [r4], r2
			sub [r4], heap

			mov r4, entrysizes
			add r4, [dp]
			mov [r4], r0

			_drop                   ; (-- addr)

			jmp .return
		..sizeNotMet:

		..loop_continue:
			add r3, 1
			cmp r3, heapsize
			jnae .loop
			;else return 0

	.return_null:
		dpush 0
	.return:
		popa
		ret

;removes the allocation of a pointer (if its in the heap)
free: ;(ptr -- )
	push r0
	push r1
	dpop r0
	sub r0, heap
	dpush r0
	call getEntryAtOffset
	dpop r1
	cmp r1, 0xFFFF
	je .return
		add r0, entryoffsets
		mov [r0], 0xFFFF
	.return:
		pop r1
		pop r0
		ret

;returns the size of a pointer in memory
sizeof: ;(ptr -- size)
	push r0
	call getEntryAtOffset
	dpop r0
	cmp r0, 0xFFFF
	je .return_fail
		add r0, entrysizes
		dpush [r0]
		jmp .return
	.return_fail:
		dpush 0
	.return:
		pop r0
		ret

%endif