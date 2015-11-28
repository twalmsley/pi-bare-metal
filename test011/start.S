.section ".text.startup"

.include "../lib/constants.h"

.global _start

.equ NUM_INTS, 256

.arm

_start:
    ldr pc, _reset_h
    ldr pc, _undefined_instruction_vector_h
    ldr pc, _software_interrupt_vector_h
    ldr pc, _prefetch_abort_vector_h
    ldr pc, _data_abort_vector_h
    ldr pc, _unused_handler_h
    ldr pc, _interrupt_vector_h
    ldr pc, _fast_interrupt_vector_h

_reset_h:                           .word   _reset_
_undefined_instruction_vector_h:    .word   undefined_instruction_vector
_software_interrupt_vector_h:       .word   software_interrupt_vector
_prefetch_abort_vector_h:           .word   prefetch_abort_vector
_data_abort_vector_h:               .word   data_abort_vector
_unused_handler_h:                  .word   _reset_
_interrupt_vector_h:                .word   interrupt_vector
_fast_interrupt_vector_h:           .word   fast_interrupt_vector

undefined_instruction_vector:
    mov     pc, lr
software_interrupt_vector:
    mov     pc, lr
prefetch_abort_vector:
    mov     pc, lr
data_abort_vector:
    mov     pc, lr
fast_interrupt_vector:
    mov     pc, lr

_reset_:
    mov     r0, #0x8000
    mov     r1, #0x0000
    ldmia   r0!,{r2, r3, r4, r5, r6, r7, r8, r9}
    stmia   r1!,{r2, r3, r4, r5, r6, r7, r8, r9}
    ldmia   r0!,{r2, r3, r4, r5, r6, r7, r8, r9}
    stmia   r1!,{r2, r3, r4, r5, r6, r7, r8, r9}


    mov r0, #(CPSR_MODE_IRQ | CPSR_IRQ_INHIBIT | CPSR_FIQ_INHIBIT )
    msr cpsr_c, r0
    mov sp, #0x8000

    mov r0, #(CPSR_MODE_SVR | CPSR_IRQ_INHIBIT | CPSR_FIQ_INHIBIT )
    msr cpsr_c, r0
    //
    // DON'T FORGET TO SUBTRACT THE gpu_mem VALUE (SEE CONFIG.TXT ON THE SD CARD)
    //
    mov     sp, #(448 * (1024 * 1024)) - 4

	bl _enable_interrupts
	bl uart0_init
	bl malloc_init
	//
	// Try the merge function
	//
	ldr r0, =merge_data1	// Pointer to the words
	mov r1, #0				// first index
	mov r2, #10				// last index
	bl f_merge_sort
	//
	// Display the result
	//
	ldr r0, =merge_data1	// Pointer to the words
	mov r1, #11				// The number of words
	bl dump_buffer
	//
	//bl test1
	//
	//
	// Start the terminal
	//
	bl uart0_terminal
spin_loop:
	b spin_loop
//------------------------------------------------------------------
// test 1
//------------------------------------------------------------------
test1:
	push {lr}

	//
	// Create a buffer and set its values to random-ish data
	//
	mov r0, #NUM_INTS		// A number of words
	bl malloc				// Allocate some memory
	mov r4, r0				// Save the address for later
	//
	// Create 100 random numbers and store in the memory buffer
	//
	mov r5, #NUM_INTS
	sub r5, #1
rand_loop:
	bl pseud_rand			// r0 now contains a random number
	str r0, [r4, r5, lsl #2]
	subs r5, #1
	bge rand_loop
	//
	// Display the list
	//
	mov r0, r4			// r0 points to the data words
	mov r1, #NUM_INTS	// r1 is the number of data words
	bl dump_buffer
	//
	// Call a search function to find a value and return its index
	//
	mov r0, r4			// r0 points to the data words
	mov r1, #NUM_INTS		// r1 is the number of data words
	ldr r2, [r0, #(NUM_INTS/2)<<2]	// This is the word we're searching for
	bl f_search
	//
	// Display the result (in r0)
	//
show_result:
	mov r1, #0
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	//
	// Call a function to sort the list using insertion sort, then display the list
	//
	mov r0, r4				// r0 points to the data words
	mov r1, #0				// r1 is the first index
	mov r2, #NUM_INTS-1		// r2 is the last index
	bl f_merge_sort
	//
	// Display the list
	//
	mov r0, r4				// r0 points to the data words
	mov r1, #NUM_INTS		// r1 is the number of data words
	bl dump_buffer
	pop {pc}
//------------------------------------------------------------------
dump_buffer:
	push {r4-r6, lr}
	mov r4, #0
	mov r5, r0
	mov r6, r1
loop_1:
	ldr r0, [r5], #4
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #','
	bl uart0_write_byte
	mov r0, #' '
	bl uart0_write_byte
	subs r6, #1
	bne loop_1

	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	pop {r4-r6, pc}
//------------------------------------------------------------------
_enable_interrupts:
    mrs     r0, cpsr
    bic     r0, r0, #0x80
    msr     cpsr_c, r0

    mov     pc, lr
//------------------------------------------------------------------
merge_data1:
	.word 11,10,9,8,7,6,5,4,3,2,1
//------------------------------------------------------------------
// End
//------------------------------------------------------------------
