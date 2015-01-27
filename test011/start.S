.section ".text.startup"

.include "../lib/constants.h"

.global _start

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
	//
	// Call a search function to find a value and return its index
	//
	ldr r0, =data_words// r0 points to the data words
	ldr r1, n_data_words// r1 is the number of data words
	mov r2, #6			// This is the word we're searching for
	bl search_func
	//
	// Display the result (in r0) - should be 4 the first time, but 3 after sort
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
	ldr r0, =data_words// r0 points to the data words
	ldr r1, n_data_words// r1 is the number of data words
	bl f_insertion_sort
	//
	// Display the list
	//
	ldr r0, =data_words// r0 points to the data words
	ldr r1, n_data_words// r1 is the number of data words
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
	//
	// Start the terminal
	//
	bl uart0_terminal
spin_loop:
	b spin_loop
//------------------------------------------------------------------
_enable_interrupts:
    mrs     r0, cpsr
    bic     r0, r0, #0x80
    msr     cpsr_c, r0

    mov     pc, lr
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
// Uses a linear search to find the first occurrance of a value
// or returns 0 if not found
//
// r0 = pointer to the data items
// r1 = the number of items
// r2 = the value to be searched for
//------------------------------------------------------------------
search_func:
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
data_words:
	.word 0,7,37,745,6,86,9,2,37,26,1
n_data_words:
	.word 11
//------------------------------------------------------------------
