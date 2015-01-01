//
//  uart_terminal.S
//  ARM-library
//
//  Created by Tony Walmsley on 31/12/2014.
//  Copyright (c) 2014 Tony Walmsley. All rights reserved.
//
.section ".text"

.equ TERM_MAX_CMDLINE, 400

.include "constants.h"
.global uart0_terminal

.extern _reset_

//------------------------------------------------------------------
// Start a uart text terminal at 19200 baud, 8N1
//
// Assumes the screen is initialised and the timers and interrupts
// are enabled. Enables the cursor itself.
//------------------------------------------------------------------
uart0_terminal:
	push {r4, lr}

	bl uart0_init
	bl uart0_terminal_prompt
	bl scr_enable_cursor
	//
	// Initialise the heap and allocate a command line buffer
	//
	bl heap_init
	mov r0, #TERM_MAX_CMDLINE
	bl heap_alloc_buffer
	str r0, term_cmd_line_ptr
	//
	// Mark it as empty
	//
	mov r0, #0
	str r0, term_cmd_line_char_count
	//
	// Enter the command loop
	//
uart0_loop:
	bl uart0_data_ready
	cmp r0, #0
	beq uart0_loop

	bl uart0_read_data
	mov r4, r0			// Save the character for further processing.
	bl print_char
	//
	// If a \r or \n was entered process the command and reprint the prompt
	//
	cmp r4, #'\r'
	beq uart0_terminal_cmd
	cmp r4, #'\n'
	beq uart0_terminal_cmd
	cmp r4, #0x08
	beq uart0_terminal_backspace
	cmp r4, #0x7F
	beq uart0_terminal_backspace
	//
	// Add the character to the command buffer if there's room
	//
	mov r0, r4
	bl uart0_write_byte	// Echo it back
	bl uart0_terminal_cmd_append

	b uart0_loop

uart0_terminal_exit:
	pop {r4, pc}

uart0_terminal_cmd:
	//
	// User entered \n or \r, so echo both back
	//
	mov r0, #'\r'
	bl uart0_write_byte	// Echo it back
	mov r0, #'\n'
	bl uart0_write_byte	// Echo it back
	//
	// Now process the command in the buffer
	//
	bl uart0_terminal_cmd_reset
	bl uart0_terminal_cmd_quit
	//
	// Clear the command buffer and show the command prompt
	//
	bl uart0_terminal_cmd_clear
	bl uart0_terminal_prompt
	b uart0_loop				// Jump back into the command loop

uart0_terminal_backspace:
	mov r0, #0x08

	ldr r1, term_cmd_line_char_count
	cmp r1, #0
	subgt r1, #1
	strgt r1, term_cmd_line_char_count
	blgt uart0_write_byte	// Echo back

	b uart0_loop				// Jump back into the command loop
//------------------------------------------------------------------
// Handle 'reset'
//------------------------------------------------------------------
uart0_terminal_cmd_reset:
	push {lr}

	ldr r0, term_cmd_line_ptr
	ldr r1, =term_reset_cmd
	ldr r2, term_reset_cmd_len
	ldr r3, term_cmd_line_char_count

	cmp r2, r3	// If the command buffer isn't the same length as the command then return
	popne {pc}

	bl util_byte_compare
	cmp r0, #1
	moveq pc, #0	//Restart the program from the _reset_ vector

	pop {pc}
//------------------------------------------------------------------
// Handle 'quit'
//------------------------------------------------------------------
uart0_terminal_cmd_quit:
	push {lr}

	ldr r0, term_cmd_line_ptr
	ldr r1, =term_quit_cmd
	ldr r2, term_quit_cmd_len
	ldr r3, term_cmd_line_char_count

	cmp r2, r3	// If the command buffer isn't the same length as the command then return
	popne {pc}

	bl util_byte_compare
	cmp r0, #1
	popeq {lr}				// Restore the stack
	beq uart0_terminal_exit	// Exit the terminal program

	pop {pc}
//------------------------------------------------------------------
// Append the char in r0 to the command buffer if there is room
//------------------------------------------------------------------
uart0_terminal_cmd_append:
	ldr r1, term_cmd_line_char_count
	cmp r1, #TERM_MAX_CMDLINE
	movge pc, lr					// No room, so just ignore

	ldr r2, term_cmd_line_ptr
	strb r0, [r2, r1]

	add r1, #1
	str r1, term_cmd_line_char_count
	mov pc, lr
//------------------------------------------------------------------
// Clear the command buffer
//------------------------------------------------------------------
uart0_terminal_cmd_clear:
	mov r0, #0
	str r0, term_cmd_line_char_count
	mov pc, lr
//------------------------------------------------------------------

term_cmd_line_ptr:
	.word 0
term_cmd_line_char_count:
	.word 0
//------------------------------------------------------------------
// Display the prompt
//------------------------------------------------------------------
uart0_terminal_prompt:
	push {lr}
	//
	// Send to the Pi screen
	//
	ldr r0, =ready_msg
	ldr r1, ready_msg_len
	bl print_str
	//
	// Send to the uart
	//
	ldr r0, =ready_msg
	ldr r1, ready_msg_len
	bl uart0_write_bytes
	pop {pc}
//------------------------------------------------------------------
ready_msg:
	.string ">"
.align
ready_msg_len:
	.word 1
term_reset_cmd:
	.string "reset"
.align
term_reset_cmd_len:
	.word 5
term_quit_cmd:
	.string "quit"
.align
term_quit_cmd_len:
	.word 4