.section ".text.startup"

.include "../lib/constants.h"

.global _start

.extern interrupt_vector
.extern int_set_callback2
.extern scr_init
.extern scr_init_frame
.extern scr_set_colours
.extern print_str
.extern print_char
.extern print_int
.extern print_hex
.extern scr_enable_cursor
.extern gfx_rect
.extern gfx_fill_rect

.extern uart_init

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

    //
    // Set up the video frame buffer
    //
	bl scr_init
    ldr r0, foreground
    ldr r1, background
	bl scr_set_colours
    bl scr_init_frame

	bl init_arm_timer
	bl _enable_interrupts

	ldr r0, =ready_msg
	ldr r1, ready_msg_len
	bl print_str

	bl uart_init

	bl scr_enable_cursor

uart_loop:
	bl uart_data_ready
	cmp r0, #0
	beq uart_loop

	bl uart_read_data
	cmp r0, #'\r'
	moveq r0, #'\n'
	bl print_char

	b uart_loop

spin_loop:
	b spin_loop
//------------------------------------------------------------------
_enable_interrupts:
    mrs     r0, cpsr
    bic     r0, r0, #0x80
    msr     cpsr_c, r0

    mov     pc, lr
//------------------------------------------------------------------

background:
	.word 0xFF404040
foreground:
	.word 0xFFFFFFFF

ready_msg:
	.string ">"
.align
ready_msg_len:
	.word 1
newline:
	.string "\n"
//------------------------------------------------------------------
