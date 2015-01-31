.section ".text"

.global malloc_init
.global malloc
.global free

.equ  HEAP_SEGMENT_COUNT_OFF,     0x00
.equ  HEAP_SEG_NEXT_PTR_OFF,      0x04
.equ  HEAP_NEXT_FREE_SEG_OFF,     0x08

.equ  HEAP_SEG_SIZE_OFF,          0x00

.pool

//------------------------------------------------------------------
// malloc - A simple version of malloc, my own design, so probably
// not very good.
//
// Data Structure
//
// head->NEXT_PTR->NEXT_PTR->NULL
// NULL<-PREV_PTR<-PREV_PTR
//       N_WORDS   N_WORDS
//       IN_USE    IN_USE
//       WORD_1    WORD_1
//         .         .
//         .         .
//         .         .
//       WORD_N    WORD_N
//------------------------------------------------------------------
m_head:
	.word	0
//------------------------------------------------------------------
malloc_init:	// Set an initial 50Mword buffer that is free
//------------------------------------------------------------------
	ldr r0, =__end__
	str r0, m_head
	mov r1, #0
	str r1, [r0], #4		// NEXT_PTR = null
	str r1, [r0], #4		// PREV_PRT = null
	mov r1, #50<<20			// Allocate 50Mwords, 200Mbytes
	sub r1, #16				// minus space for the header
	str r1, [r0], #4		// N_WORDS = 50Mwords
	mov r1, #0
	str r1, [r0], #4		// IN_USE = 0
	ldr r0, m_head
	mov pc, lr
//------------------------------------------------------------------
// malloc
//
//	r0 = n bytes requested
//	r1 = m_head
//	while (r1[2] < n and r1[3] == 1 and r1[0] <> null)
//		r1 = r1[0]
//	if(r1 <> null)
//		r0 = split_buffer
//	else
//		r0 = 0
//	return r0
//
//------------------------------------------------------------------
malloc:			// Allocate some memory
//------------------------------------------------------------------
	push {lr}
	ldr r1, m_head

malloc_while_loop:
//	while (r1[2] < n and r1[3] == 1 and r1[0] <> null)

	ldr r2, [r1, #2<<2]				// Get current node size
	cmp r2, r0
	blt malloc_while_loop_next

	ldr r2, [r1, #3<<2]				// Get current node in-use flag
	cmp r2, #1
	bne malloc_while_loop_end

malloc_while_loop_next:
	ldr r1, [r1]
	cmp r1, #0
	bne malloc_while_loop

malloc_while_loop_end:
//	if(r1 <> null)
	cmp r1, #0
//		r0 = split_buffer
	moveq r0, #0
	blne malloc_split
//	return r0

	pop {pc}
//------------------------------------------------------------------
// malloc_split
//
// r0 is the required number of words
// r1 points to a free node structure, the memory needs splitting
// return a pointer to the memory area in r0
//
//------------------------------------------------------------------
malloc_split:			// Split a free buffer in 2, allocating the
						// first buffer and returning a pointer to
						// it in r0
//------------------------------------------------------------------
	push {r4-r9, lr}

	ldr r7, [r1]				// Current NEXT_PTR
	ldr r8, [r1, #4]			// Current PREV_PTR

	ldr r4, [r1, #2<<2]			// Size of current buffer
	sub r4, r0					// subtract the words we're allocating
	sub r4, #4					// subtract space for the node header
	//
	// Is the remaining size worth splitting or just allocating as-is?
	//
	cmp r4, #10
	bgt malloc_split_continue
	//
	// Just allocate this node
	//
	mov r5, #1
	str r5, [r1, #3<<2]			// Mark it as in-use
	b malloc_split_ret

malloc_split_continue:
	str r0, [r1, #2<<2]			// Update the current node's size
	mov r5, #1
	str r5, [r1, #3<<2]			// Mark it as in-use

	add r5,	r1, r0, lsl #2		// nbytes to add = size * 4
	add r5, #4<<2				// r5 points to the new next node
	str r5, [r1]				// Update current node's NEXT_PTR

	mov r6, #0
	str r7, [r5]				// New node's NEXT_PTR
	str r1, [r5, #1<<2]			// New node's PREV_PTR
	str r4, [r5, #2<<2]			// New node's size
	str r6, [r5, #3<<2]			// New node marked as free

	tst r7, r7
	strne r5, [r7, #4]			// Next node's PREV_PTR

malloc_split_ret:
	add r0, r1, #16
	pop {r4-r9, pc}
//------------------------------------------------------------------
// Free a buffer for re-use
// r0 points to the memory
//------------------------------------------------------------------
free:
	cmp r0, #0
	moveq pc, lr
	mov r1, #0
	str r1, [r0, #-4]
	moveq pc, lr
//------------------------------------------------------------------
// End
//------------------------------------------------------------------
