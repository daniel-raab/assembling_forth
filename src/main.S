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
.type reset_handler, %function
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

// get character
.type getc, %function
getc:
	ADD r7, #1
	BLX lr

