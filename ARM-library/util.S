.section ".text"

.global util_r0_delay
.global pseud_rand
.global pseud_rand_seeds
.global util_block_transfer
.global util_block_fill
.global util_byte_compare

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
PRNG_X: .word 83276498
PRNG_Y: .word 38239823
PRNG_Z: .word 37924710
PRNG_W: .word 93847181

//------------------------------------------------------------------
// Get the next pseudo random in r0
//------------------------------------------------------------------
pseud_rand:
	push {r4, r5, lr}
	ldr r0, PRNG_X
	ldr r1, PRNG_Y
	ldr r2, PRNG_Z
	ldr r3, PRNG_W

	mov r4, r0, LSL #11
	eor r4, r4, r0
	eor r4, r4, LSR #8

	str r1, PRNG_X
	str r2, PRNG_Y
	str r3, PRNG_Z

	mov r5, r3, LSR #19
	eor r3, r5

	eor r3, r4

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
//------------------------------------------------------------------
