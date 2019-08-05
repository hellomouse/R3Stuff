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

;gets an entry index at heap offset
getEntryAtOffset: ; ( offset -- entry# )
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
getFirstEmptyEntry: ; ( -- entry# )
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
emptyEntryExists: ;( -- bool )
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
malloc: ; ( size -- ptr )
	pusha ;im tired of register pressure
	
	dpop r0 ;requested size

	mov r4, 0 ;found address
	mov r5, 0 ;size counter
	
	;check if theres an empty entry slot, return if not
	call emptyEntryExists
	dpop r1
	cmp r1, 1
	jne .return_null
	
		
	;loop:
	mov r1, 0
	.loop:
		;check if entry exists at location, continue if so
		dpush r1
		call getEntryAtOffset
		dpop r2
		cmp r2, 0xFFFF
		je .noEntryAtOffset
			add r2, entrysizes
			add r1, [r2]
			sub r1, 1
			mov r5, 0 ;reset the size counter too
			jmp .loop_continue
		.noEntryAtOffset:
		
		;check if we're working on an address, set it to the loop's iterator + heap
		cmp r4, 0
		jne .alreadyWorkingOnAnAddress
			mov r4, r1
			add r4, heap ;foundAddr = offsetCounter + heap
			mov r5, 0    ;reset size counter just incase
		.alreadyWorkingOnAnAddress:
		
		;add 1 to size counter
		add r5, 1
		
		;if we have the wanted size:
		cmp r5, r0
		jnae .sizeIsNotMet
			;get first empty entry
			call getFirstEmptyEntry
			dpop r5 ;reuse sizeCounter as it's not necessary anymore
					;plus using size requested is safer for size operations
			;set that entry's offset to foundAddr - heap
			mov r2, entryoffsets ;reuse r2 aswell
			add r2, r1           ;r2 = entryoffsets[sizecounter]
			mov [r2], r4
			sub [r2], heap       ;entryoffsets[sizecounter] = foundAddr - heap
			;set size to requested size
			mov r2, entrysizes   ;reuse r2
			add r2, r1           ;r2 = entrysizes[sizecounter]
			mov [r2], r0         ;entrysizes[sizecounter] = size
			;return foundAddr
			dpush r4
			jmp .return_successful
		.sizeIsNotMet:
	.loop_continue:
	add r1, 1
	cmp r1, heapsize
	jnae .loop
	jmp .return_null
	.return_null:
		dpush 0
		jmp .return
	.return_successful:
	.return:
		popa
		ret
	
free: ;( ptr -- )
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

%endif