//
//  gfx.S
//  ARM-library
//
//  Created by Tony Walmsley on 29/12/2014.
//  Copyright (c) 2014 Tony Walmsley. All rights reserved.
//
.section ".text"

.include "constants.h"

.global gfx_rect
.global gfx_fill_rect

//-------------------------------------------------------------------------------------------
// gfx_fill_rect - draw a filled rectangle at the current coords of size x=r0, y=r1
//-------------------------------------------------------------------------------------------
gfx_fill_rect:
	push {r4-r8, lr}
	sub sp, #12
	//
	// sp[0] = x-dimension
	// sp[4] = y-dimension
	// sp[8] = foreground colour
	//
	str r0, [sp]
	str r1, [sp, #4]
	//
	// Get and store the foreground colour
	//
	bl scr_get_foreground
	str r0, [sp, #8]
	//
	// Get a pointer to the pixel at XY
	//
	bl scr_get_xy_ptr
	mov r1, r0 // Save frame buffer pointer to XY pixel

	ldr r0, [sp, #8]	//Foreground colour
	ldr r5, [sp, #4]	//y-dimension counter
	ldr r4, [sp]		//x-dimension counter

gfx_fill_rect_loop:
	bl scr_plot

	add r1, #4
	subs r4, #1
	bne gfx_fill_rect_loop

	add r1, #SCREEN_X*4
	ldr r4, [sp]		//x-dimension counter
	sub r1, r4, lsl #2

	subs r5, #1
	bne gfx_fill_rect_loop

	add sp, #12
	pop {r4-r8, pc}
//-------------------------------------------------------------------------------------------
// gfx_rect - draw a rectangle at the current coords of size x=r0, y=r1
//-------------------------------------------------------------------------------------------
gfx_rect:
	push {r4-r8, lr}

	mov r3, r0 // Use x as a counter
	mov r4, r1 // Use y as a counter
	mov r7, r0 // Save x dimension
	mov r8, r1 // Save y dimension

	bl scr_get_xy
	mov r5, r0 // Save x coord
	mov r6, r1 // Save y coord

	mov r2, r1
	mov r1, r0
	bl scr_get_foreground

gfx_rect_x_loop:
	push {r0-r3}
	bl scr_plot_xy	//display the r0 colour at the pixel coords in r1(x)  and r2(y)
	pop {r0-r3}

	push {r0-r3}
	add r2, r8
	sub r2, #1
	bl scr_plot_xy	//display the r0 colour at the pixel coords in r1(x)  and r2(y)
	pop {r0-r3}

	add r1, #1
	subs r3, #1
	bne gfx_rect_x_loop

	mov r1, r5	// reload the x coord
gfx_rect_y_loop:
	push {r0-r3}
	bl scr_plot_xy	//display the r0 colour at the pixel coords in r1(x)  and r2(y)
	pop {r0-r3}

	push {r0-r3}
	add r1, r7
	subs r1, #1
	bl scr_plot_xy	//display the r0 colour at the pixel coords in r1(x)  and r2(y)
	pop {r0-r3}

	add r2, #1
	subs r4, #1
	bne gfx_rect_y_loop

	pop {r4-r8, pc}
