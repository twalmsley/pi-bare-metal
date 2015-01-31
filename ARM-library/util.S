.section ".text"

.global util_r0_delay
.global pseud_rand
.global pseud_rand_seeds
.global util_block_transfer
.global util_block_fill
.global util_byte_compare
.global util_itoa

//------------------------------------------------------------------
// Counts down until r0 is 0
//------------------------------------------------------------------
util_r0_delay:
    subs r0, #1
    moveq pc, lr
    b util_r0_delay

//------------------------------------------------------------------
// Set the seed values for the PRNG
// Pass them in r0-r3
//------------------------------------------------------------------
pseud_rand_seeds:
	str r0, PRNG_X
	str r1, PRNG_Y
	str r2, PRNG_Z
	str r3, PRNG_W
	mov pc, lr
PRNG_X: .word 1
PRNG_Y: .word 2
PRNG_Z: .word 3
PRNG_W: .word 4

//------------------------------------------------------------------
// Get the next pseudo random in r0
//
// uint32_t xorshift128(void) {
//     uint32_t t = x ^ (x << 11);
//     x = y; y = z; z = w;
//     return w = w ^ (w >> 19) ^ t ^ (t >> 8);
// }
//------------------------------------------------------------------
pseud_rand:
	push {r4, r5, lr}
	ldr r0, PRNG_X
	ldr r1, PRNG_Y
	ldr r2, PRNG_Z
	ldr r3, PRNG_W

	mov r4, r0, LSL #11		// t = x<<11
	eor r4, r4, r0			// t = t ^ X

	str r1, PRNG_X			// x = y
	str r2, PRNG_Y			// y = z
	str r3, PRNG_Z			// z = w

	mov r5, r3, LSR #19		// r5 = w>>19
	eor r3, r5				// w = (w>>19) ^ w

	eor r3, r4				// w = (w>>19) ^ w ^ t
	eor r4, r4, LSR #8		// t = t >> 8
	eor r3, r4				// w = (w>>19) ^ w ^ t ^ (t>>8)

	str r3, PRNG_W
	mov r0, r3
	pop {r4, r5, pc}
//------------------------------------------------------------------
// Block transfer words - r0 = dest, r1 = src, r2=nwords
//
// transfers 8 words at a time. dest < src or if not then the areas
// must not overlap otherwise the src will be corrupted before copy
//------------------------------------------------------------------
util_block_transfer:
	push {r4-r12, lr}

	mov r4, r2
	movs r3, r2, lsr #3	// r3 is the number of 8 word blocks to move

	beq util_block_remainder	// Skip if zero
	
util_block_loop1:
	ldm r1!, {r5-r12}
	stm r0!, {r5-r12}
	subs r3, #1
	bne util_block_loop1

util_block_remainder:
	ands r4, #7			// r4 is the remaining number of words
	beq util_block_exit	// Skip if zero

util_block_loop2:
	ldr r5, [r1], #4
	str r5, [r0], #4
	subs r4, #1
	bne util_block_loop2
util_block_exit:
	pop {r4-r12, pc}
//------------------------------------------------------------------
// Block transfer words - r0 = dest, r1 = fill value, r2=nwords
//
// transfers 8 words at a time. dest < src or if not then the areas
// must not overlap otherwise the src will be corrupted before copy
//------------------------------------------------------------------
util_block_fill:
	push {r4-r12, lr}

	mov r4, r2
	movs r3, r2, lsr #3	// r3 is the number of 8 word blocks to move

	beq util_block_fill_remainder	// Skip if zero

	mov r5, r1
	mov r6, r1
	mov r7, r1
	mov r8, r1
	mov r9, r1
	mov r10, r1
	mov r11, r1
	mov r12, r1
util_block_fill_loop1:
	stm r0!, {r5-r12}
	subs r3, #1
	bne util_block_fill_loop1

util_block_fill_remainder:
	ands r4, #7			// r4 is the remaining number of words
	beq util_block_fill_exit	// Skip if zero

util_block_fill_loop2:
	str r5, [r0], #4
	subs r4, #1
	bne util_block_fill_loop2
util_block_fill_exit:
	pop {r4-r12, pc}
//------------------------------------------------------------------
// Block compare bytes - r0 = dest, r1 = src, r2=nbtes
// r0 = 1 if they are the same
//------------------------------------------------------------------
util_byte_compare:
	push {r4-r5, lr}

util_byte_compare_loop1:
	ldrb r4, [r0],#1
	ldrb r5, [r1],#1

	and r4, #0xFF
	and r5, #0xFF
	cmp r4, r5
	movne r0, #0
	bne util_byte_compare_exit	// Exit if the bytes are different

	subs r2, #1
	bne util_byte_compare_loop1

	mov r0, #1
util_byte_compare_exit:
	pop {r4-r5, pc}
//--------------------------------------------------------------------------------------
// itoa
// r0 = integer value to print
// r1 = 1 to print leading zeros
//
// Returns pointer to string in r0 and length in r1
//--------------------------------------------------------------------------------------
util_itoa:
	push {r4, r5, r6, r7, r8, r9, lr}
	ldr r6, =util_format_buffer
	mov r9, #0			// used to count the actual digits in the buffer
	ldr r2, =util_powers_of_10

	mov r3, #0		// Digit counter - 0 to 9
	mov r8, #0		// 0 means we haven't printed a digit yet - used when skipping leading zeros
util_itoa_next_digit:
	ldr r5, [r2, r3, lsl #2]
	mov r4, #0		// value of current decimal digit position

util_itoa_count:
	cmp r0, r5
	addge r4, #1
	subge r0, r5
	bge util_itoa_count
	//
	// r4 now contains the digit
	//
	teq r4, #0
	movne r8, #1		// Flag that we have started the non-zero digits
	bne util_itoa_continue
	//
	// Its a zero, but is it a leading zero?
	//
	cmp r8, #0
	bne util_itoa_continue	// Not a leading zero
	//
	// Its a leading zero, but should we be printing leading zeros?
	//
	cmp r1, #1
	beq util_itoa_continue	// Print leading zeros
	//
	// Skip leading zero, unless its the last zero
	//
	cmp r3, #9
	beq util_itoa_continue // Its the last digit and also a leading zero, so print it anyway
	//
	// Skip it
	//
	add r6, #1
	b util_itoa_loop_end_check

util_itoa_continue:
	add r4, #0x30			// Convert to ASCII
	strb r4, [r6], #1		// Store it in the buffer
	add r9, #1
util_itoa_loop_end_check:
	//
	// get the next power of 10 constant
	//
	add r3, #1
	cmp r3, #10
	blt util_itoa_next_digit
	//
	// Print the buffer chars and return the length in r0
	//
	ldr r0, =util_format_buffer
	//
	// Adjust for skipped leading zeros
	//
	add r0, #10
	sub r0, r9
	mov r1, r9					// String length
	pop {r4, r5, r6, r7, r8, r9, pc}
//--------------------------------------------------------------------------------------
util_format_buffer:
	.string "9999999999"
.align
util_powers_of_10:
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
