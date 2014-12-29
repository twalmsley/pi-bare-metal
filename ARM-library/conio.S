//
//  conio.S
//  ARM-library
//
//  Created by Tony Walmsley on 28/12/2014.
//  Copyright (c) 2014 Tony Walmsley. All rights reserved.
//
.section ".text"

.include "constants.h"

.global print_str
.global print_int

//--------------------------------------------------------------------------------------
// print_str
// r0 = ascii string pointer
// r1 = string length
//--------------------------------------------------------------------------------------
print_str:
	push {lr}
print_str_loop:
	push {r0, r1}
	bl scr_draw_char
	pop {r0, r1}
	
	add r0, #1
	subs r1, #1
	bne print_str_loop

	pop {pc}
//--------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------
// print_int
// r0 = integer value to print
// r1 = 1 to print leading zeros
//--------------------------------------------------------------------------------------
print_int:
	push {r4, r5, r6, r7, r8, r9, lr}
	ldr r6, =conio_format_buffer
	mov r9, #0			// used to count the actual digits in the buffer
	ldr r2, =conio_powers_of_10

	mov r3, #0		// Digit counter - 0 to 9
	mov r8, #0		// 0 means we haven't printed a digit yet - used when skipping leading zeros
print_int_next_digit:
	ldr r5, [r2, r3, lsl #2]
	mov r4, #0		// value of current decimal digit position

print_int_count:
	cmp r0, r5
	addge r4, #1
	subge r0, r5
	bge print_int_count
	//
	// r4 now contains the digit
	//
	teq r4, #0
	movne r8, #1		// Flag that we have started the non-zero digits
	bne print_int_continue
	//
	// Its a zero, but is it a leading zero?
	//
	cmp r8, #0
	bne print_int_continue	// Not a leading zero
	//
	// Its a leading zero, but should we be printing leading zeros?
	//
	cmp r1, #1
	beq print_int_continue	// Print leading zeros
	//
	// Skip leading zero, unless its the last zero
	//
	cmp r3, #9
	beq print_int_continue // Its the last digit and also a leading zero, so print it anyway
	//
	// Skip it
	//
	add r6, #1
	b print_int_loop_end_check

print_int_continue:
	add r4, #0x30			// Convert to ASCII
	strb r4, [r6], #1		// Store it in the buffer
	add r9, #1
print_int_loop_end_check:
	//
	// get the next power of 10 constant
	//
	add r3, #1
	cmp r3, #10
	blt print_int_next_digit
	//
	// Print the buffer chars and return the length in r0
	//
	ldr r0, =conio_format_buffer
	//
	// Adjust for skipped leading zeros
	//
	add r0, #10
	sub r0, r9
	mov r1, r9					// String length
	bl print_str

	mov r0, r4
	pop {r4, r5, r6, r7, r8, r9, pc}
//--------------------------------------------------------------------------------------
conio_format_buffer:
	.string "9999999999"
.align
conio_powers_of_10:
	.word 1000000000
	.word 100000000
	.word 10000000
	.word 1000000
	.word 100000
	.word 10000
	.word 1000
	.word 100
	.word 10
	.word 1
