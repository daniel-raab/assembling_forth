/**
 * @file  		core.S
 * @defgroup   	Basic Project
 *
 * @brief      	This file contains the vector table of the microcontroller.
 *
 * @author     	Daniel Raab
 * @date       	11.06.2021
 */

.syntax unified // choose unified arm assembler syntax
.cpu cortex-m3 // choose the cpu architecture
.fpu softvfp
.thumb // select thumb instruction set
// for more information on instruction set and syntax, see
// https://stackoverflow.com/questions/28669905/what-is-the-difference-between-the-arm-thumb-and-thumb-2-instruction-encodings

// setup stack pointer to end of RAM
	.equ stack_size, 0x2000 // 8kB
	.equ _estack, 0x20000000+stack_size

// the vector table
.type vtable, %object
vtable:
	.word 0x0 // dummy value
	.word reset_handler
.size vtable, .-vtable


// buffer characters
	.data
input_array:
	.space 100

// reset handler, called on reset
	.text
adr_input_array:
	.word input_array

	.global _start
	.type reset_handler, %function
_start:
reset_handler:
	// setup stack pointer to end of RAM
	ldr sp, =_estack
	interpret:
		ldr r1, adr_input_array // r1 contains address to next character in input_array
		type:
			// get character: into r0
			bl getc
			// save character into input_array
			strb r0, [r1]
			add r1, r1, #1
			b type
		b    interpret
.size reset_handler, .-reset_handler

// returns next input character in r0
	.data
input:	.asciz "1 2 3 . . .\n"
next_c:	.word input
	.text
	.type getc, %function
adr_next_c: .word next_c
getc:
	// uses r1, r2
	push {r1, r2}
	ldr r1, adr_next_c // get address of next character address
	ldr r2, [r1] // address of next character
	// load next character
	ldrb r0, [r2]
	// check for end of string
	cmp r0, #0
	itt NE
	addne r2, r2, #1
	strne r2, [r1]
	// return
	pop {r1, r2}
	blx lr
