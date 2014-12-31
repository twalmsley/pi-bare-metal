//
//  uart.S
//  ARM-library
//
//  Created by Tony Walmsley on 30/12/2014.
//  Copyright (c) 2014 Tony Walmsley. All rights reserved.
//
.section ".text"

.include "constants.h"
.global uart_init
.global uart_data_ready
.global uart_read_data

UART_BASE:
	.word 0x20201000
GPIO_BASE:
	.word 0x20200000
	//
	// Divisors set for 19200baud at 300MHz
	//
UART_BAUD_INT:
	.word 9
UART_BAUD_FRACTION:
	.word 49
//------------------------------------------------------------------
// Initialise the uart
//------------------------------------------------------------------
uart_init:
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
	ldr r0, UART_BASE
	mov r1, #0
	str r1, [r0, #UART_CR]
	//
	// Set the baud rate divisor regs
	//
	ldr r1, UART_BAUD_INT
	ldr r2, UART_BAUD_FRACTION
	str r1, [r0, #UART_IBRD]
	str r2, [r0, #UART_FBRD]
	//
	// Setup the UART line control register
	//
	mov r1, #0
	orr r1, #(3<<UART_LCRH_WLEN) | (1<<UART_LCRH_FEN)
	str r1, [r0, #UART_LCRH]
	//
	// Setup the interrupts if needed
	//
	mov r1, #0
	str r1, [r0, #UART_ICR]							// Clear any interrupts
	//
	// Setup the UART control register
	//
	mov r1, #0
	orr r1, #(1<<UART_CR_RXE) | (0<<UART_CR_TXE)	// Enable receive
	str r1, [r0, #UART_CR]							// Update the CR
	orr r1, #(1<<UART_CR_UARTEN)					// Also enable the UART
	str r1, [r0, #UART_CR]							// Update the CR again
	pop {pc}
//------------------------------------------------------------------
// Check whether there is any data to read = r0 = 1 if yes
//------------------------------------------------------------------
uart_data_ready:
	push {lr}
	ldr r0, UART_BASE
	ldr r1, [r0, #UART_FR]
	tst r1, #(1<<UART_FR_RXFE)
	movne r0, #0
	moveq r0, #1
	pop {pc}
//------------------------------------------------------------------
// Read data and return it in r0
//------------------------------------------------------------------
uart_read_data:
	push {lr}
	ldr r1, UART_BASE
	ldr r0, [r1, #UART_DR]
	and r0, #0xFF			// Ignore the error bits for now.
	pop {pc}
