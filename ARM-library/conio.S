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
.global print_char
.global print_int
.global print_hex

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
// print_char
// r0 = ascii character
//--------------------------------------------------------------------------------------
print_char:
	push {lr}
	bl scr_draw_char_in_r0
	pop {pc}
//--------------------------------------------------------------------------------------
// Print a hex word - word is in r0
//--------------------------------------------------------------------------------------
print_hex:
	push {r4-r6, lr}

	ldr r4, =conio_hex_digits	// Pointer to the hex digit table
	mov r5, #28					// Shift amount
	mov r6, r0					// Save the original param value

print_hex_digit_loop:
	mov r0, r6
	lsr r0, r5					// Shift the required nibble to the LSbits

	and r0, #0xF				// Mask the nibble
	ldrb r0, [r4, r0]			// Get the hex digit
	and r0, #0xFF				// Just in case

	bl scr_draw_char_in_r0		// Draw the digit
	subs r5, #4					// Adjust the shift amount
	bge print_hex_digit_loop

	pop {r4-r6, pc}
//--------------------------------------------------------------------------------------
// print_int
// r0 = integer value to print
// r1 = 1 to print leading zeros
//--------------------------------------------------------------------------------------
print_int:
	push {r4, r5, r6, r7, r8, r9, lr}
	bl util_itoa
	bl print_str

	mov r0, r4
	pop {r4, r5, r6, r7, r8, r9, pc}
//--------------------------------------------------------------------------------------
conio_hex_digits:
	.string "0123456789ABCDEF"
.align
