.section ".text"

.include "constants.h"

.global scr_init
.global scr_init_frame
.global scr_set_colours
.global scr_set_xy
.global scr_plot_xy
.global scr_plot
.global scr_draw_char
.global scr_draw_char_in_r0
.global scr_draw_sprite32
.global scr_draw_sprite16
.global scr_get_xy
.global scr_get_xy_ptr
.global scr_get_foreground
.global scr_enable_cursor
.global SCR_FB_POINTER

//-------------------------------------------------------------------------------------------------
// Init frame buffer structure
//-------------------------------------------------------------------------------------------------
scr_init:
    ldr r0,=FB_STRUCT
    orr r0,#1 // MAIL_FB channel 1 is the frame buffer channel
    ldr r1,MB_WRITE
    str r0,[r1] // Mail Box Write

MBox_Read: 
    ldr r1,MB_READ
    ldr r0,[r1]
    tst r0,#1 // Compare Frame Buffer Channel 1
    beq MBox_Read // Wait For Frame Buffer Channel 1 Data

    ldr r0,=SCR_FB_POINTER // R0 = Frame Buffer Pointer
    ldr r0, [r0]
    tst r0,r0 // Compare Frame Buffer Pointer to Zero
    beq scr_init
    mov pc, lr

//-------------------------------------------------------------------------------------------------
// Init frame buffer to background
//-------------------------------------------------------------------------------------------------
scr_init_frame:
    push {lr}

    ldr r3, background

    ldr r0,=SCR_FB_POINTER // R0 = Frame Buffer Pointer
    ldr r0, [r0]

    mov r1, #(SCREEN_Y*SCREEN_X)
init_frame_loop:
    str r3, [r0],#4
    subs r1, #1
    bne init_frame_loop

    pop {pc}
//-------------------------------------------------------------------------------------------------
// scr_set_colours - r0 = foreground, r1 = background
//-------------------------------------------------------------------------------------------------
scr_set_colours:
	str r0, foreground
	str r1, background
	mov pc, lr
//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------
// scr_set_xy - r0 = x, r1 = y
//-------------------------------------------------------------------------------------------------
scr_set_xy:
	str r0, scr_draw_x
	str r1, scr_draw_y
	mov pc, lr
//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
// scr_draw_char - r0 points to the char byte, use current screen coords
//-------------------------------------------------------------------------------------------------
scr_draw_char_in_r0:				// Alternative entry
	push {r4, r5, r6, r7, r8, lr}
	b scr_char_already_in_r0
scr_draw_char:
	push {r4, r5, r6, r7, r8, lr}
	//
	// Mask off the unwanted bits
	//
	ldrb r0, [r0]
	and r0, #0xff
scr_char_already_in_r0:
	//
	// Handle some of the ASCII control characters
	//
	teq r0, #'\n'
	beq scr_draw_char_new_line
	teq r0, #'\r'
	beq scr_draw_char_new_line
	teq r0, #0x08				// Backspace
	beq scr_draw_char_backspace
	teq r0, #0x7F				// Backspace
	beq scr_draw_char_backspace

scr_draw_char_skip_special:
	//
	// Get a pointer to the drawing position
	//
	ldr r6, =SCR_FB_POINTER
	ldr r6, [r6]

	ldr r7,scr_draw_x
	add r6, r7, lsl #2

	ldr r7, scr_draw_y
	mov r8, #SCREEN_X
	mul r7, r8
	add r6, r7, lsl #2

	//
	// Get a pointer to the font
	//
	ldr r1, =scr_font
	add r1, r0, lsl #3	// Add the current char offset
	//
	// Loop for 8 font bytes and 8 bits per byte
	//
	mov r2, #8			// Byte counter

scr_draw_char_next_byte:
	ldrb r4, [r1]		// Load the bitmap byte
	and r4, #0xFF
	mov r3, #(1<<7)			// Bit mask
scr_draw_char_next_bit:
	//
	// Load the right pixel colour
	//
	tst r4, r3
	ldreq r5, background
	ldrne r5, foreground
	//
	// Store it in the screen buffer
	//
	push {r0, r1, r2, r3}
	mov r0, r5
	mov r1, r6
	bl scr_plot
	pop {r0, r1, r2, r3}
	add r6, #4

scr_draw_char_bit_loop_end:
	lsrs r3, #1
	bne scr_draw_char_next_bit

scr_draw_char_byte_loop_end:
	add r1, #1
	add r6, #4*(SCREEN_X-8)
	subs r2, #1
	bne scr_draw_char_next_byte
	//
	// Shift the x and y positions accordingly
	//
	ldr r4, scr_draw_x
	cmp r4, #(SCREEN_X-16)
	addle r4, #8
	strle r4, scr_draw_x
	pople {r4, r5, r6, r7, r8, pc}

	bl scr_new_line
	pop {r4, r5, r6, r7, r8, pc}	// Return

scr_draw_char_new_line:
	bl scr_cursor_off
	bl scr_new_line
	bl scr_enable_cursor
	pop {r4, r5, r6, r7, r8, pc}	// Return

scr_draw_char_backspace:
	bl scr_cursor_off
	bl scr_backspace
	bl scr_enable_cursor
	pop {r4, r5, r6, r7, r8, pc}	// Return
//-------------------------------------------------------------------------------------------------
// scr_new_line - move the text 'cursor' to the start of the next line
//-------------------------------------------------------------------------------------------------
scr_new_line:
	push {r4, lr}
	mov r4, #0
	str r4, scr_draw_x
	ldr r4, scr_draw_y
	//
	// Need to scroll?
	//
	cmp r4, #(SCREEN_Y-8)
	blge scr_scroll
	addlt r4, #8
	strlt r4, scr_draw_y

	pop {r4, pc}
//-------------------------------------------------------------------------------------------------
// scr_backspace - go back one character if there's room
//-------------------------------------------------------------------------------------------------
scr_backspace:
	push {r4, lr}

	ldr r0, scr_draw_x
	cmp r0, #8
	poplt {r4, pc}		// Not enough room to backspace

	sub r0, #8
	str r0, scr_draw_x
	//
	// Draw a 'space'
	//
	mov r0, #' '
	bl scr_draw_char_in_r0
	//
	// Move the cursor back again
	//
	ldr r0, scr_draw_x
	sub r0, #8
	str r0, scr_draw_x
	pop {r4, pc}
//-------------------------------------------------------------------------------------------------
// scr_scroll - move the screen up one line (8 pixel rows)
//-------------------------------------------------------------------------------------------------
scr_scroll:
	push {lr}
	//
	// Get a pointer to the start of the screen
	//
	ldr r0, =SCR_FB_POINTER
	ldr r0, [r0]
	//
	// Get a pointer 8 pixel-rows further down
	//
	mov r1, r0
	add r1, #(SCREEN_X*8*4)
	//
	// Set a counter for the number of words to move
	//
	mov r2, #(SCREEN_X*SCREEN_Y)
	sub r2, #(SCREEN_X*8)

	bl util_block_transfer
	//
	// Clear the bottom 8 rows to the background colour
	//
	mov r2, #(SCREEN_X*8)
	ldr r3, background

scr_scroll_loop2:
	str r3, [r0], #4
	subs r2, #1
	bne scr_scroll_loop2

	pop {pc}
//-------------------------------------------------------------------------------------------------
// Draw a 32x32 sprite pointed to by r0
//-------------------------------------------------------------------------------------------------
scr_draw_sprite32:
	push {r4, r5, r6, r7, lr}
	//
	// Get a pointer to the drawing position
	//
	ldr r6, =SCR_FB_POINTER
	ldr r6, [r6]

	ldr r7,scr_draw_x
	add r6, r7, lsl #2

	ldr r7, scr_draw_y
	mov r8, #SCREEN_X
	mul r7, r8
	add r6, r7, lsl #2
	//
	// Loop for 32 sprite words and 32 bits per word
	//
	mov r2, #0			// Word counter

scr_draw_sprite_next_word32:
	ldr r4, [r0], #4		// Load the bitmap byte
	mov r3, #(1<<31)			// Bit mask
scr_draw_sprite_next_bit32:
	//
	// Load the right pixel colour
	//
	tst r4, r3
	ldreq r5, background
	ldrne r5, foreground
	//
	// Store it in the screen buffer
	//
	push {r0, r1, r2, r3}
	mov r0, r5
	mov r1, r6
	bl scr_plot
	pop {r0, r1, r2, r3}
	add r6, #4
scr_draw_sprite_bit_loop_end32:
	lsrs r3, #1
	bne scr_draw_sprite_next_bit32

scr_draw_sprite_byte_loop_end32:
	add r6, #4*(SCREEN_X-32)
	add r2, #1
	cmp r2, #32
	bne scr_draw_sprite_next_word32

	pop {r4, r5, r6, r7, pc}

//-------------------------------------------------------------------------------------------------
// Draw a 16x16 sprite pointed to by r0
//-------------------------------------------------------------------------------------------------
scr_draw_sprite16:
	push {r4, r5, r6, r7, lr}
	//
	// Get a pointer to the drawing position
	//
	ldr r6, =SCR_FB_POINTER
	ldr r6, [r6]

	ldr r7,scr_draw_x
	add r6, r7, lsl #2

	ldr r7, scr_draw_y
	mov r8, #SCREEN_X
	mul r7, r8
	add r6, r7, lsl #2
	//
	// Loop for 16 sprite shorts and 16 bits per short
	//
	mov r2, #0			// Word counter

scr_draw_sprite_next_word16:
	ldrh r4, [r0], #2		// Load the bitmap byte
	mov r3, #(1<<15)			// Bit mask
scr_draw_sprite_next_bit16:
	//
	// Load the right pixel colour
	//
	tst r4, r3
	ldreq r5, background
	ldrne r5, foreground
	//
	// Store it in the screen buffer
	//
	push {r0, r1, r2, r3}
	mov r0, r5
	mov r1, r6
	bl scr_plot
	pop {r0, r1, r2, r3}
	add r6, #4
scr_draw_sprite_bit_loop_end16:
	lsrs r3, #1
	bne scr_draw_sprite_next_bit16

scr_draw_sprite_byte_loop_end16:
	add r6, #4*(SCREEN_X-16)
	add r2, #1
	cmp r2, #16
	bne scr_draw_sprite_next_word16

	pop {r4, r5, r6, r7, pc}

//-------------------------------------------------------------------------------------------------
// scr_plot_xy - display the r0 colour at the pixel coords in r1(x)  and r2(y)
//-------------------------------------------------------------------------------------------------
scr_plot_xy:
	push {r4, lr}
	ldr r3, =SCR_FB_POINTER
	ldr r3, [r3]						// r3 points to the screen
	//
	// Calculate the offset and plot it
	//
	add r3, r1, lsl #2

	mov r4, #SCREEN_X
	mul r2, r4
	add r3, r2, lsl #2

	mov r1, r3
	bl scr_plot

	pop {r4, pc}
//-------------------------------------------------------------------------------------------------
// scr_plot - display the r0 colour at the address in r1
//-------------------------------------------------------------------------------------------------
scr_plot:
	ldr r3, =SCR_FB_POINTER
	ldr r3, [r3]						// r3 points to the screen
	//
	// Check we're actually in the frame buffer
	//
	cmp r1, r3
	movlt pc, lr
	add r3, #4*(SCREEN_X*SCREEN_Y)
	cmp r1, r3
	movge pc, lr
	//
	// Coords are OK, so plot it
	//
	str r0, [r1]
	mov pc, lr
//-------------------------------------------------------------------------------------------------
// Get the current xy coords
//-------------------------------------------------------------------------------------------------
scr_get_xy:
	ldr r0, scr_draw_x
	ldr r1, scr_draw_y
	mov pc, lr

//-------------------------------------------------------------------------------------------------
// Get pointer to the current xy pixel
//-------------------------------------------------------------------------------------------------
scr_get_xy_ptr:
	ldr r0, =SCR_FB_POINTER
	ldr r0, [r0]						// r0 points to the screen

	ldr r1,scr_draw_x
	add r0, r1, lsl #2

	ldr r1, scr_draw_y
	mov r2, #SCREEN_X
	mul r1, r2
	add r0, r1, lsl #2
	mov pc, lr
//-------------------------------------------------------------------------------------------------
// Get the current foreground colour
//-------------------------------------------------------------------------------------------------
scr_get_foreground:
	ldr r0, foreground
	mov pc, lr
//-------------------------------------------------------------------------------------------------
// Add a callback to flash the cursor
//-------------------------------------------------------------------------------------------------
scr_enable_cursor:
	push {lr}
	ldr r0, =scr_cursor_callback
	bl int_set_callback1
	pop {pc}
//-------------------------------------------------------------------------------------------------
// Callback function used to flash the cursor
//-------------------------------------------------------------------------------------------------
scr_cursor_callback:
	push {r4-r6, lr}

	ldr r4, scr_cursor_blink_count
	add r4, #1
	cmp r4, #976/4 // About 0.25 secs
	bne scr_cursor_callback_exit
	//
	// Reset the counter and toggle the cursor
	//
	mov r4, #0
	ldr r5, scr_cursor_blink_onoff
	tst r5, r5
	moveq r5, #1
	movne r5, #0
	str r5, scr_cursor_blink_onoff
	//
	// convert the value in r5 to a foreground or background colour as necessary
	//
	teq r5, #1
	ldreq r5, foreground
	ldrne r5, background

	bl scr_get_xy_ptr	// in r0
	add r0, #(4*7*SCREEN_X)

	mov r6, #8	// 8-pixel underscore
scr_cursor_loop:
	str r5, [r0], #4
	subs r6, #1
	bne scr_cursor_loop

scr_cursor_callback_exit:
	str r4, scr_cursor_blink_count
	pop {r4-r6, pc}

scr_cursor_blink_count:
	.word 0x0
scr_cursor_blink_onoff:
	.word 0x0	// 0 = 0ff, 1 = on
//-------------------------------------------------------------------------------------------------
// Hide the cursor while we change screen position
//-------------------------------------------------------------------------------------------------
scr_cursor_off:
	push {r4-r6, lr}

	moveq r0, #0
	bl int_set_callback1	// Disable the cursor callback

	ldr r5, background

	bl scr_get_xy_ptr	// in r0
	add r0, #(4*7*SCREEN_X)

	mov r6, #8	// 8-pixel underscore
scr_cursor_off_loop:
	str r5, [r0], #4
	subs r6, #1
	bne scr_cursor_off_loop

	pop {r4-r6, pc}
//-------------------------------------------------------------------------------------------------
foreground: .word 0xFFFFFFFF
background: .word 0xFF000000

scr_draw_x: .word 0x0
scr_draw_y: .word 0x0

MB_READ:  .word 0x2000B880 // PERIPHERAL_BASE + MAIL_BASE + MAIL_READ
MB_WRITE: .word 0x2000B8A0 // PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_FB

.section ".text.data"

FB_STRUCT: // Frame Buffer Structure
  .word SCREEN_X // Frame Buffer Pixel Width 
  .word SCREEN_Y // Frame Buffer Pixel Height 
  .word SCREEN_X // Frame Buffer Virtual Pixel Width 
  .word SCREEN_Y // Frame Buffer Virtual Pixel Height 
  .word 0 // Frame Buffer Pitch (Set By GPU) 
  .word BITS_PER_PIXEL // Frame Buffer Bits Per Pixel 
  .word 0 // Frame Buffer Offset In X Direction 
  .word 0 // Frame Buffer Offset In Y Direction 
SCR_FB_POINTER:
  .word 0 // Frame Buffer Pointer (Set By GPU) 
  .word 0 // Frame Buffer Size (Set By GPU)

.include "font.inc"
