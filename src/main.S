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

// global memory locations (available in other files)
.global vtable
.global reset_handler

// the vector table
.type vtable, %object
vtable:
	.word 0x12345678
	.word reset_handler
.size vtable, .-vtable

// reset handler, called on reset
.global _start
.type reset_handler, %function
_start:
reset_handler:
	// application: load dummy value into register r7
	LDR  r7, =0xDEADBEEF
	MOVS r0, #0
	main_loop:
		ADDS r0, r0, #2
		BL getc
		// jump back to label main_loop, creating an endless loop
		B    main_loop
.size reset_handler, .-reset_handler

// returns next input character in r0, uses r1
	.data
input:	.asciz "1 2 3 . . .\n"
next_c:	.word input
	.text
	.type getc, %function
adr_next_c: .word next_c
getc:
	LDR r1, adr_next_c // get address of next character address
	LDR r2, [r1] // address of next character
	// load next character
	LDRB r0, [r2]
	// check for end of string
	CMP r0, #0
	ITT NE
	ADDNE r2, r2, #1
	STRNE r2, [r1]
	// return
	BLX lr
