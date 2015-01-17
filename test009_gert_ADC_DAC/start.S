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
.extern uart0_terminal
.extern uart0_init
.extern gert_spi_dac_init
.extern gert_spi_dac_write
.extern util_r0_delay
.extern util_itoa

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

	//
	// Init UART0
	//
	bl uart0_init
	//
	// Init SPI
	//
	bl gert_spi_init
	mov r0, #1				// DAC channel 1
	mov	r1, #0x80<<4		// Half voltage
	bl gert_spi_dac_write

adc_read_loop:
	mov r0, #0				// ADC channel 0
	bl gert_spi_adc_read

	mov r4, r0 // Save the ADC value just read
	//
	// Print value to the screen
	//
	mov r1, #0
	bl print_int
	mov r0, #'\n'
	bl print_char
	//
	// Print value to the uart
	//
	mov r0, r4
	mov r1, #0
	bl util_itoa
	bl uart0_write_bytes
	mov r0, #'\r'
	bl uart0_write_byte
	mov r0, #'\n'
	bl uart0_write_byte
	//
	// Wait a while and try again
	//
	mov r0, #1<<23
	bl util_r0_delay
	b adc_read_loop

	bl uart0_terminal

	ldr r0, =terminal_exit_msg
	ldr r1, terminal_exit_msg_len
	bl print_str

	ldr r0, =terminal_exit_msg
	ldr r1, terminal_exit_msg_len
	bl uart0_write_bytes

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
//------------------------------------------------------------------
terminal_exit_msg:
	.string "Terminal has exited.\n"
.align
terminal_exit_msg_len:
	.word 21
