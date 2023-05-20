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
	.equ dstack, 0x20000000+stack_size
	.equ rstack, dstack+stack_size

// the vector table
.type vtable, %object
vtable:
	.word 0x0 // dummy value
	.word reset_handler
.size vtable, .-vtable

//---------------- REGISTERS ---------------------
/*
 The registers and their use is as follows:

low registers
	R0
	R1
	R2
	R3
	R4
	R5
	R6
	R6
	R7
	R8
	
high registers: can only be used with 32 Bit thumb instructions
	R9
	R10	address of first dictionary entry
	R11	return stack pointer
	R12	data stack pointer

special purpose registers
	SP	either return or data stack pointer
	LR
	PC
 */

// switch SP to return stack
.macro return_stack
	// save data stack pointer
	mrs r12, msp
	// put return stack in SP
	msr msp, r11	
.endm

// switch SP to data stack
.macro data_stack
	// save return stack pointer
	mrs r11, msp
	// put data stack in SP
	msr msp, r12
.endm


// ----------------- _start: entry point -------------------
// reset handler, called on reset
	.global _start
	.type reset_handler, %function
_start:
reset_handler:
	// setup data stack pointer to end of RAM
	ldr r12, =dstack
	ldr r11, =rstack
	ldr sp, =rstack
	ldr r10, =DOT

	interpret:
		// r1 contains the address to the (unwritten) character in input_array
		// r0 will get the next character from the input
		ldr r1, adr_input_array // r1 contains address to next character in input_array

		// read characters into input_array until line feed
		type:
			// get character: into r0
			bl getc
			// if the character is a newline, the input will be evaluated
			cmp r0, #'\n'
			beq eval
			// save character into input_array
			strb r0, [r1]
			add r1, r1, #1
			b type
	
		// evaluate all words in input_array until line feed
		// r8: beginning of current word
		// r7: address of current definition
		// r0: character of word
		// r1: character of definition
		// r2: index of character in word
		// r4: in char_match
		eval:
			// get address of input and definition
			ldr r8, adr_input_array

		no_match:
			mov r7, r10
			ldr r2, =#0
			// get first character of word
			ldrb r0, [r8, r2]	
			// compare word character with definition character
			ldrb r1, [r7, #4]
			cmp r0, r1
			beq char_match
		next_definition:
			// not a match, get next definition (if it exists)
			ldr r7, [r7]
			cmp r7, #0			
			bne no_match
			// no more definitions, try to parse as number
		parse_number:
			// only decimal numbers for now
			// TODO: > 10, negative
			subs r0, #'0'
			bmi eval_error // if negative
			cmp r0, #10
			bge eval_error // if not 0-9
			// number parsed! Save to data stack
			data_stack
			push {r0}
			return_stack
			// dummy increment index
			add r2, r2, #1
			b eval_more
			// first characters match, check until termination
			char_match:
				add r2, r2, #1
				ldrb r0, [r8, r2]
				add r3, r7, #4 // r3 contains beginning of definition word
				ldrb r1, [r3, r2]
				// check for space and convert to null termination
				cmp r0, #' '
				it eq
				ldreq r0, =0
				// compare word char with definition char
				cmp r0, r1
				bne next_definition // no match
				cmp r0, #0
				bne char_match // not yet null termination, check rest of word
				// match! execute word
				// get start of definition code (skip name and padding)
				// offset has to be multiple of 2
				tst r2, #1
				ite ne
				addne r4, r2, #1
				moveq r4, r2
				add r7, r3, r4 
				// bit 0 has to be 1, for thumb state, see https://developer.arm.com/documentation/dui0489/i/arm-and-thumb-instructions/blx
				orr r7, r7, #1
				blx r7

			// word is done, more words?
			eval_more:
				// check if current character is null termination
				ldrb r0, [r8, r2]
				cmp r0, #0
				beq eval_ok // done
				// set pointer to new word
				add r2, r2, #1
				add r8, r8, r2
				b no_match

		// error, not defined and not a number
		eval_error:
			ldr r0, ='~'
			bl putc
			ldr r0, ='\n'
			bl putc
			b interpret
		
		// executed everything: ok.
		eval_ok:
			ldr r0, ='o'
			bl putc
			ldr r0, ='k'
			bl putc
			ldr r0, ='.'
			bl putc
			ldr r0, ='\n'
			bl putc
	
		b    interpret
.size reset_handler, .-reset_handler


//--------- INPUT/OUTPUT ---------------
	.data
input:	
	.asciz "1 2 3 . . .\n"
// input/output buffers
input_array:
	.space 100
output_array:
	.space 100
next_input_char:	
	.word input
next_output_char:
	.word output_array

	.text
adr_input_array:
	.word input_array
adr_output_array:
	.word output_array


// returns next input character in r0
	.text
	.type getc, %function
adr_next_input_char: 
	.word next_input_char
getc:
	// uses r1, r2
	push {r1, r2}
	ldr r1, adr_next_input_char // get address of next character address
	ldr r2, [r1] // address of next character
	// load next character
	ldrb r0, [r2]
	// check for end of string
	cmp r0, #0
	itt NE
	addne r2, r2, #1
	strne r2, [r1]
	
	pop {r1, r2}
	bx lr


// putc: prints the character in r0 to output_array
	.text
	.type putc, %function
adr_next_output_char:
	.word next_output_char
putc:
	push {r1, r2}
	// store character in output_array
	ldr r1, adr_next_output_char
	ldr r2, [r1]
	str r0, [r2]
	// increment pointer to next output character
	add r2, r2, #1
	str r2, [r1]
	
	pop {r1, r2}
	bx lr
	


//----------- FORTH WORDS -------------------
/*
forth words have the following memory layout (from jones forth):

	  pointer to previous word
	   ^
	   |
	+--|------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+--|---------+------------+------------+
           ^       len                         pad  codeword      |
	   |							  V
	  LINK in next word				points to codeword of DUP
*/
	.text

// .
DOT:
	.type Lheader, %object
Lheader:
	.word 0 // first word, null pointer
	.asciz "."
	.align 2
	.size Lheader, .-Lheader
DOT_start:
	push {lr}
	// get value from stack
	data_stack
	pop {r0}
	return_stack
	// convert to ascii
	// TODO: >10, negative
	add r0, r0, #'0'
	bl putc
	ldr r0, =' '
	bl putc
	// return
	pop {pc}
