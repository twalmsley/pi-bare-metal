//
//  uart.S
//  ARM-library
//
//  Created by Tony Walmsley on 30/12/2014.
//  Copyright (c) 2014 Tony Walmsley. All rights reserved.
//
.section ".text"

.include "constants.h"
.global uart0_init
.global uart0_data_ready
.global uart0_read_data
.global uart0_write_byte
.global uart0_write_bytes

UART0_BASE:
	.word 0x20201000
GPIO_BASE:
	.word 0x20200000
	//
	// Divisors set for 19200baud at 300MHz
	//
UART0_BAUD_INT:
	.word 9
UART0_BAUD_FRACTION:
	.word 49
//------------------------------------------------------------------
// Initialise the uart
//------------------------------------------------------------------
uart0_init:
	push {lr}
	//
	// Set up the GPIO14 and 15 pins
	//
	mov r0, #0b100	// Alt function 0
	mov r1, #0
	orr r1, r0, lsl #12	// GPIO 14 Alt Function - Tx0
	orr r1, r0, lsl #15 // GPIO 15 Alt Function - Rx0
	ldr r0, GPIO_BASE
	str r1, [r0, #RPI_GPFSEL1]
	//
	// Make sure the UART is disabled
	//
	ldr r0, UART0_BASE
	mov r1, #0
	str r1, [r0, #UART0_CR]
	//
	// Set the baud rate divisor regs
	//
	ldr r1, UART0_BAUD_INT
	ldr r2, UART0_BAUD_FRACTION
	str r1, [r0, #UART0_IBRD]
	str r2, [r0, #UART0_FBRD]
	//
	// Setup the UART line control register
	//
	mov r1, #0
	orr r1, #(3<<UART0_LCRH_WLEN) | (1<<UART0_LCRH_FEN)
	str r1, [r0, #UART0_LCRH]
	//
	// Setup the interrupts if needed
	//
	mov r1, #0
	str r1, [r0, #UART0_ICR]							// Clear any interrupts
	//
	// Setup the UART control register
	//
	mov r1, #0
	orr r1, #(1<<UART0_CR_RXE) | (1<<UART0_CR_TXE)	// Enable transmit and receive
	str r1, [r0, #UART0_CR]							// Update the CR
	orr r1, #(1<<UART0_CR_UARTEN)					// Also enable the UART
	str r1, [r0, #UART0_CR]							// Update the CR again
	pop {pc}
//------------------------------------------------------------------
// Check whether there is any data to read = r0 = 1 if yes
//------------------------------------------------------------------
uart0_data_ready:
	push {lr}
	ldr r0, UART0_BASE
	ldr r1, [r0, #UART0_FR]
	tst r1, #(1<<UART0_FR_RXFE)
	movne r0, #0
	moveq r0, #1
	pop {pc}
//------------------------------------------------------------------
// Read data and return it in r0
//------------------------------------------------------------------
uart0_read_data:
	push {lr}
	ldr r1, UART0_BASE
	ldr r0, [r1, #UART0_DR]
	and r0, #0xFF			// Ignore the error bits for now.
	pop {pc}
//------------------------------------------------------------------
// Write byte, wait for the fifo if necessary
// r0 - byte to send
//------------------------------------------------------------------
uart0_write_byte:
	push {lr}
	ldr r1, UART0_BASE

uart0_tx_fifo_wait:
	ldr r2, [r1, #UART0_FR]
	tst r2, #(1<<UART0_FR_TXFF)
	bne uart0_tx_fifo_wait
	//
	// Write the byte.
	//
	strb r0, [r1, #UART0_DR]

	pop {pc}
//------------------------------------------------------------------
// Write bytes, wait for the fifo if necessary
// r0 - pointer to bytes
// r1 - number of bytes
//------------------------------------------------------------------
uart0_write_bytes:
	push {lr}
	ldr r3, UART0_BASE

uart0_write_bytes_loop:
	ldr r2, [r3, #UART0_FR]
	tst r2, #(1<<UART0_FR_TXFF)
	bne uart0_write_bytes_loop
	//
	// Write the byte.
	//
	ldrb r2, [r0], #1
	strb r2, [r3, #UART0_DR]
	subs r1, #1
	bne uart0_write_bytes_loop

	pop {pc}
//------------------------------------------------------------------
