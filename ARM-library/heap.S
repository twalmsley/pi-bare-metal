.section ".text"

.global heap_init
.global heap_alloc_buffer

.equ  HEAP_SEGMENT_COUNT_OFF,     0x00
.equ  HEAP_SEG_NEXT_PTR_OFF,      0x04
.equ  HEAP_NEXT_FREE_SEG_OFF,     0x08

.equ  HEAP_SEG_SIZE_OFF,          0x00

.pool

//------------------------------------------------------------------
heap_init:
	//
	// Skip if we're already initialised
	//
	ldr r0, heap_initialised
	tst r0, r0
	bne heap_init_exit
	mov r0, #1
	str r0, heap_initialised
    //
    // Get the free memory pointer in r0
    //
    ldr r0, =__end__
    //
    // Set the number of allocated segments to zero and the 
    // address of the first segment to zero
    //
    mov r1, #0
    str r1, [r0, #HEAP_SEGMENT_COUNT_OFF]
    str r1, [r0, #HEAP_SEG_NEXT_PTR_OFF]
    //
    // Set the pointer to the next free segment
    //
    add r1, r0, #0x0C
    str r1, [r0, #HEAP_NEXT_FREE_SEG_OFF]
heap_init_exit:
    mov pc, lr
//------------------------------------------------------------------
heap_initialised:
	.word 0
//------------------------------------------------------------------
// Allocate r0 bytes on the heap and update a linked list
// return the address of the block in r0
//------------------------------------------------------------------
heap_alloc_buffer:
    push {r4, lr}
    //
    // Get a pointer to the next free segment in r2
    //
    ldr r1, =__end__
    ldr r2, [r1, #HEAP_NEXT_FREE_SEG_OFF]
    //
    // Set up the segment structure - size, next ptr
    //
    str r0, [r2, #HEAP_SEG_SIZE_OFF]
    mov r3, #0
    str r3, [r2, #HEAP_SEG_NEXT_PTR_OFF]
    //
    // Update the segment count
    //
    ldr r4, [r1, #HEAP_SEGMENT_COUNT_OFF]
    add r4, #1
    str r4, [r1, #HEAP_SEGMENT_COUNT_OFF]
    //
    // Link the segment to the chain
    //
    push {r0, r1}
    bl heap_find_end_of_linked_list // returned in r0
    str r2, [r0]
    pop {r0, r1}
    //
    // Update the next free seg pointer
    //
    add r2, #8      // Add the link header overhead
    mov r4, r2      // Need the value of r2 later - store it in r4 for now
    add r2, r0      // Add the number of requested bytes
    str r2, [r1, #HEAP_NEXT_FREE_SEG_OFF] // store it as the next free segment
    //
    // Return the address of the segment in r0
    //
    mov r0, r4
heap_alloc_buffer_exit:
    pop {r4, pc}
//------------------------------------------------------------------
// Follow the liked list pointers to find the end
//------------------------------------------------------------------
heap_find_end_of_linked_list: // return in r0
    //
    // Get the start of the list
    //
    ldr r0, =__end__

heap_find_end_of_linked_list_next:
    add r0, #HEAP_SEG_NEXT_PTR_OFF
    ldr r1, [r0]
    //
    // If r0 is zero then return r0
    //
    cmp r1, #0
    beq heap_find_end_of_linked_list_exit
    //
    // Otherwise follow the link and test again
    //
    mov r0, r1
    b heap_find_end_of_linked_list_next

heap_find_end_of_linked_list_exit:
    mov pc, lr
