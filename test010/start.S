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

	bl init_arm_timer
	bl _enable_interrupts
	bl uart0_init
	//
	// Test the malloc and free routines
	//
	bl malloc_init
	mov r1, #0
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	//
	// Allocate 100 words and print the pointer value
	//
	mov r0, #100
	bl malloc
	mov r4, r0		// Save the buffer pointer
	mov r1, #0
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	mov r0, r4			// Free the buffer
	bl free
	//
	// Allocate 200 words and print the pointer value
	//
	mov r0, #200
	bl malloc
	mov r4, r0		// Save the buffer pointer
	mov r1, #0
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	mov r0, r4			// Free the buffer
	bl free
	//
	// Allocate 50 words and print the pointer value
	//
	mov r0, #50
	bl malloc
	mov r4, r0		// Save the buffer pointer
	mov r1, #0
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	mov r0, r4			// Free the buffer
	bl free
	//
	// Allocate 40 words and print the pointer value
	//
	mov r0, #40
	bl malloc
	mov r4, r0		// Save the buffer pointer
	mov r1, #0
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	mov r0, r4			// Free the buffer
	bl free
	//
	// Allocate 200 words and print the pointer value
	//
	mov r0, #200
	bl malloc
	mov r4, r0		// Save the buffer pointer
	mov r1, #0
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	mov r0, r4			// Free the buffer
	bl free
	//
	// Allocate 200 words and print the pointer value
	//
	mov r0, #200
	bl malloc
	mov r4, r0		// Save the buffer pointer
	mov r1, #0
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	mov r0, r4			// Free the buffer
	bl free
	//
	// Allocate 200 words and print the pointer value
	//
	mov r0, #200
	bl malloc
	mov r4, r0		// Save the buffer pointer
	mov r1, #0
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	mov r0, r4			// Free the buffer
	bl free
	//
	// Allocate 200 words and print the pointer value
	//
	mov r0, #200
	bl malloc
	mov r4, r0		// Save the buffer pointer
	mov r1, #0
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	mov r0, r4			// Free the buffer
	bl free
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
