.section ".text"

.global util_r0_delay
.global pseud_rand
.global pseud_rand_seeds
.global util_block_transfer
.global util_block_fill
.global util_byte_compare
.global util_itoa
.global f_insertion_sort
.global f_selection_sort
.global f_search

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
//------------------------------------------------------------------
// Uses insertion sort to sort the integers in-place
// r0 = pointer to the data items
// r1 = the number of items
//------------------------------------------------------------------
f_insertion_sort:
	push {r4-r8, lr}

	mov r4, #2					// for j = 2 to A.length
f_insertion_sort_for_loop:
	ldr r5, [r0, r4, lsl #2]	// key = A[j]

	mov r6, r4					// i = j-1
f_insertion_sort_while:
	subs r6, #1

	ble f_insertion_sort_1		// while i > 0 and A[i] > key
	ldr r7, [r0, r6, lsl #2]
	cmp r7, r5
	ble f_insertion_sort_1

	add r8, r6, #1				// A[i+1] = A[i]
	str r7, [r0, r8, lsl #2]

	b f_insertion_sort_while

f_insertion_sort_1:
	add r8, r6, #1				// A[i+1] = key
	str r5, [r0, r8, lsl #2]

	adds r4, #1
	cmp r4, r1
	blt f_insertion_sort_for_loop

f_insertion_sort_return:
	pop {r4-r8, pc}
//------------------------------------------------------------------
// Uses selection sort to sort the integers in-place
// r0 = pointer to the data items
// r1 = the number of items
//
//	n = A.length
//	for i = 0 to n-2
//		smallest = A[i]
//		smallest_index = i
//		for j = i+1 to n-1
//			if A[j] < smallest
//				smallest = A[j]
//				smallest_index = j
//		tmp = A[i]
//		A[i] = smallest
//		A[smallest_index] = tmp
//
// INVARIANT: A[0..i] is in non-descending order
//
//------------------------------------------------------------------
f_selection_sort:
	push {r4-r8, lr}

	mov r4, #0					// i = 0 to n-2
	sub r5, r1, #2

f_selection_sort_iloop_start:
	ldr r6, [r0, r4, lsl #2]	// smallest = A[i]
	mov r7, r4					// smallest_index = i

	mov r8, r4					// for j = i+1 to n-1
f_selection_sort_jloop_start:
	add r8, #1
	cmp r8, r1
	bge f_selection_sort_jloop_end

	ldr r9, [r0, r8, lsl #2]	// if A[j] < smallest
	cmp r9, r6
	bge f_selection_sort_skip_if

	mov r6, r9					// smallest = A[j]
	mov r7, r8					// smallest_index = j
f_selection_sort_skip_if:
	b f_selection_sort_jloop_start

f_selection_sort_jloop_end:
	ldr r10, [r0, r4, lsl #2]	// tmp = A[i]
	str r6, [r0, r4, lsl #2]	// A[i] = smallest
	str r10, [r0, r7, lsl #2]	// A[smallest_index] = tmp

	add r4, #1
	cmp r4, r1
	blt f_selection_sort_iloop_start
f_selection_sort_return:
	pop {r4-r8, pc}
//------------------------------------------------------------------
// Uses a linear search to find the first occurrance of a value
// or returns 0 if not found
//
// r0 = pointer to the data items
// r1 = the number of items
// r2 = the value to be searched for
//------------------------------------------------------------------
f_search:
	push {r4-r5, lr}
	mov r4, #1			// Loop index
search_loop:
	ldr r5, [r0, r4, lsl #2]
	cmp r2, r5
	beq end_loop
	adds r4, #1
	cmp r4, r1
	bne search_loop

	mov r4, #0// Not found, so use 0 as the return value
end_loop:
	mov r0, r4// return the index of the element found, or 0
search_return:
	pop {r4-r5, pc}
//------------------------------------------------------------------
// Merge sort
//
// r0 = pointer to the data items
// r1 = the number of items
// r2 = p
// r3 = q
// r4 = r
//
//	MERGE (A,p,q,r)
//
//	n1 = q-p+1
//	n2 = r-q
//	new L[1..n1]
//	new R[1..n2]
//
//	for i = 1 to n1
//		L[i] = A[p+i-1]
//	for i = 1 to n2
//		R[i] = A[q+i]
//
//	i = 1
//	j = 1
//	for k = p to r
//		if i <= n1 and j <= n2 and L[i] <= R[j]
//			A[k] = L[i]
//			i = i + 1
//		if i <= n1 and j <= n2 and L[i] > R[j]
//			A[k] = R[j]
//			j = j + 1
//		if i > n1
//			A[k] = R[j]
//			j = j + 1
//		if j > n2
//			A[k] = L[i]
//			i = i + 1
//------------------------------------------------------------------
f_merge:
	push {r5-r8, lr}

	push {r0}		//[sp+16]	= pointer to A
	push {r1}		//[sp+12]	= number of items
	push {r2}		//[sp+8]	= p
	push {r3}		//[sp+4]	= q
	push {r4}		//[sp]		= r

//	n1 = q-p+1
	sub r5, r3, r2
	sub r5, #1				// r5 is n1

//	n2 = r-q
	sub r6, r4, r3			// r6 is n2

//	new L[1..n1]
	mov r0, r5
	bl malloc
	mov r7, r0				// r7 points to L

//	new R[1..n2]
	mov r0, r6
	bl malloc
	mov r8, r0				// r8 points to R

//	for i = 1 to n1
//		L[i] = A[p+i-1]
	mov r0, r7				// r0 points to L
	ldr r1, [sp, #16]		// r1 points to the start of A
	ldr r2, [sp, #8]		// r2 is p
	add r1, r2, lsl #2		// r1 points to A[p]
	mov r2, r5				// r2 is n1
	bl f_copy_words

//	for i = 1 to n2
//		R[i] = A[q+i]
	mov r0, r8				// r0 points to R
	ldr r1, [sp, #16]		// r1 points to the start of A
	ldr r2, [sp, #4]		// r2 is q
	add r1, r2, lsl #2		// r1 points to A[q]
	mov r2, r6				// r2 is n2
	bl f_copy_words

//
//	i = 1
//	j = 1
	mov r0, #0		// r0 is i
	mov r1, #0		// r1 is j

//	for k = p to r
	ldr r2, [sp, #8]		// r2 is k and starts at p
	ldr r3, [sp]			// r3 is r

f_merge_k_loop:

//		if i <= n1 and j <= n2 and L[i] <= R[j]
	cmp r0, r5
	bgt f_merge_i_gt_n1
	cmp r1, r6
	bgt f_merge_j_gt_n2
	ldr r4, [r7, r0, lsl #2]
	ldr r9, [r8, r1, lsl #2]
	cmp r4, r9
	bgt f_merge_Li_gt_Rj
	ldr r9, [sp, #16]			//			A[k] = L[i]
	str r4, [r9, r2, lsl #2]
	add r0, #1					//			i = i + 1
	b f_merge_k_loop_end

f_merge_Li_gt_Rj:
//		if i <= n1 and j <= n2 and L[i] > R[j]
	ldr r4, [sp, #16]			//			A[k] = R[j]
	str	r9, [r4, r2, lsl #2]
	add r1, #1					//			j = j + 1
	b f_merge_k_loop_end

f_merge_i_gt_n1:				// if i > n1
	ldr r4, [r8, r1, lsl #2]	// A[k] = R[j]
	ldr r9, [sp, #16]			// r9 points to A
	str r4, [r9, r2, lsl #2]	// store r4 in A[k]
	add r1, #1					// j = j + 1
	b f_merge_k_loop_end

f_merge_j_gt_n2:				// if j > n2
	ldr r4, [r7, r0, lsl #2]	// A[k] = L[i]
	ldr r9, [sp, #16]			// r9 points to A
	str r4, [r9, r2, lsl #2]	// store r4 in A[k]
	add r0, #1					// i = i + 1
	// fall through to f_merge_k_loop_end

f_merge_k_loop_end:
	add r2, #1
	cmp r2, r3
	bne f_merge_k_loop

f_merge_ret:
	mov r0, r7			// Free buffer L
	bl free
	mov r0, r8			// Free buffer R
	bl free

	add sp, #20			// restore the sp
	pop {r5-r8, pc}
//--------------------------------------------------------------------------------------
// Copy words from one buffer to another
// r0 = dest
// r1 = src
// r2 = count
//--------------------------------------------------------------------------------------
f_copy_words:
	ldr r3, [r1], #4
	str r3, [r0], #4
	subs r2, #1
	bne f_copy_words
	mov pc, lr
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
