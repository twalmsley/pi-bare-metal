//
//  uart_terminal.S
//  ARM-library
//
//  Created by Tony Walmsley on 31/12/2014.
//  Copyright (c) 2014 Tony Walmsley. All rights reserved.
//
.section ".text"

.include "constants.h"
.global uart_termnal

//------------------------------------------------------------------
// Start a uart text terminal at 19200 baud, 8N1
//
// Assumes the screen is initialised and the timers and interrupts
// are enabled. Enables the cursor itself.
//------------------------------------------------------------------
uart_termnal:
	push {lr}

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

	bl print_char

	b uart_loop

	pop {pc}
//------------------------------------------------------------------
ready_msg:
	.string ">"
.align
ready_msg_len:
	.word 1
