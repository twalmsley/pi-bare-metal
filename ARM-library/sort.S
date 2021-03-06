.section ".text"

.global f_insertion_sort
.global f_selection_sort
.global f_search
.global f_merge_sort

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
// r0 points to the aray
// r1 is the first index
// r2 is the second index
//------------------------------------------------------------------
f_merge_sort:
	push {r0-r5, lr}

	cmp r1, r2				// Recursed far enough?
	bge f_merge_sort_end

	mov r3, r0			// Save the params
	mov r4, r1			// Save the params
	mov r5, r2			// Save the params

	add r2, r1, r2
	lsr r2, #1
	bl f_merge_sort

	mov r1, r2
	add r1, #1
	mov r2, r5
	bl f_merge_sort

	mov r0, r3
	add r1, r9, #1
	mov r2, r4
	add r3, r4, r5
	lsr r3, #1
	add r3, #1
	mov r4, r5
	bl f_merge

f_merge_sort_end:
	pop {r0-r5, pc}
//------------------------------------------------------------------
// Merge
//
// r0 = pointer to the data items
// r1 = the number of items
// r2 = p - the start index
// r3 = q - index of start of next sorted subset
// r4 = r - index of the last item
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

//	n1 = q-p
	sub r5, r3, r2

//	n2 = r-q
	sub r6, r4, r3			// r6 is n2
	add r6, #1

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
	bge f_merge_i_gt_n1
	cmp r1, r6
	bge f_merge_j_gt_n2
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
	ble f_merge_k_loop

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
