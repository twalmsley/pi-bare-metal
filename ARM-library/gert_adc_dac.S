//
//  gert_adc_dac.S
//  ARM-library
//
//  Created by Tony Walmsley on 01/01/2015.
//  Copyright (c) 2015 Tony Walmsley. All rights reserved.
//
.global gert_spi_dac_init
.global gert_spi_dac_write

.section ".text"

.include "constants.h"

RPI_GPIO_BASE:
	.word             0x20200000
RPI_SPI_BASE:
	.word             0x20204000

//------------------------------------------------------------------
// Set up the spi port for the dac
//------------------------------------------------------------------
gert_spi_dac_init:
	push {lr}
	//
	// Set up the GPIO correctly for the required alternate functions
	// (7, 8, 9, 10 and 11 to ALT0)
	//
	ldr r0, RPI_GPIO_BASE
	mov r1, #(RPI_GPIO_ALT0 << 21) | (RPI_GPIO_ALT0 << 24) | (RPI_GPIO_ALT0 << 27)
	str r1, [r0, #RPI_GPFSEL0]
	mov r1, #(RPI_GPIO_ALT0 << 0) | (RPI_GPIO_ALT0 << 3)
	str r1, [r0, #RPI_GPFSEL1]
	//
	// Set the SPI clock divider to 256 (should result in ~1MHz SPI clock)
	//
	ldr r0, RPI_SPI_BASE
	mov r1, #256
	str r1, [r0, #RPI_SPI0_CLK]

	mov r1, #(RPI_SPI0_CLEAR_FIFO << 4)
	str r1, [r0, #RPI_SPI0_CS]

	pop {pc}
//------------------------------------------------------------------
// Write to the DAC - r0 is the channel, 0 or 1,
//					  r1 is the value left justified in 12 bits
//------------------------------------------------------------------
gert_spi_dac_write:
	push {lr}
	//
	// Mask so that just the lower 12 bits are used
	//
	mov r2, #0xFF
	orr r2, #0xF00
	and r1, r2
	//
	// Set up the first byte in r2
	//
	mov r2, #0x30
	orr r2, r0, lsl #7
	orr r2, r1, lsr #8
	//
	// Set up the second byte in r3
	//
	mov r3, r1
	and r3, #0xFF
	//
	// Enable the SPI and CS1
	//
	ldr r0, RPI_SPI_BASE
	ldr r1, [r0, #RPI_SPI0_CS]
	orr r1, #RPI_SPI0_CS1 | (1<<RPI_SPI0_TA)
	str r1, [r0, #RPI_SPI0_CS]
	//
	// Wait briefly to ensure the CS has been selected for a while
	//
	mov r0, #100
	bl util_r0_delay
	//
	// Put the data in the FIFO
	//
	ldr r0, RPI_SPI_BASE
	str r2, [r0, #RPI_SPI0_FIFO]
	str r3, [r0, #RPI_SPI0_FIFO]
	//
	// Wait for the DONE flag
	//
gert_spi_dac_write_loop:
	ldr r1, [r0, #RPI_SPI0_CS]
	tst r1, #(1<<RPI_SPI0_DONE)
	beq gert_spi_dac_write_loop
	//
	// Write is DONE so drain the receive fifo
	//
	ldr r1, [r0, #RPI_SPI0_FIFO]
	ldr r1, [r0, #RPI_SPI0_FIFO]
	//
	// Wait a while then disable the SPI device
	//
	mov r0, #100
	bl util_r0_delay

	ldr r0, RPI_SPI_BASE
	ldr r1, [r0, #RPI_SPI0_CS]
	bic r1, #(1<<RPI_SPI0_TA)
	str r1, [r0, #RPI_SPI0_CS]

	pop {pc}
//------------------------------------------------------------------
