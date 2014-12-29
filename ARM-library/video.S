.section ".text"

.include "constants.h"

.global scr_init
.global scr_init_frame
.global scr_set_colours
.global scr_set_xy
.global scr_draw_char
.global scr_draw_sprite32
.global scr_draw_sprite16
.global SCR_FB_POINTER

// Setup Frame Buffer
.equ SCREEN_X,       640
.equ SCREEN_Y,       480
.equ BITS_PER_PIXEL, 32

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
    tst r0,r0 // Compare Frame Buffer Pointer to Zero
    popeq {pc} // IF Zero Re-Initialize Frame Buffer

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
scr_draw_char:
	push {r4, r5, r6, r7, r8, lr}
	//
	// Mask off the unwanted bits
	//
	ldrb r0, [r0]
	and r0, #0xff
	//
	// If its a newline char then just do that and return
	//
	teq r0, #0x0A
	bne scr_draw_char_not_newline
	bl scr_new_line
	pop {r4, r5, r6, r7, r8, pc}	// Return

scr_draw_char_not_newline:
	sub r0, #0x20
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
	str r5, [r6], #4
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
	pop {r4, r5, r6, r7, r8, pc}
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
// scr_scroll - move the screen up one line (8 pixel rows)
//-------------------------------------------------------------------------------------------------
scr_scroll:
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

scr_scroll_loop:
	ldr r3, [r1], #4
	str r3, [r0], #4
	subs r2, #1
	bne scr_scroll_loop
	//
	// Clear the bottom 8 rows to the background colour
	//
	mov r2, #(SCREEN_X*8)
	ldr r3, background
scr_scroll_loop2:
	str r3, [r0], #4
	subs r2, #1
	bne scr_scroll_loop2

	mov pc, lr
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
	str r5, [r6], #4
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
	str r5, [r6], #4
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

scr_font:
.space (8*16) // leave space for punctuation
	.byte 0x78, 0x8c, 0x94, 0xa4, 0xc4, 0x84, 0x78, 0x00	// 0
	.byte 0x10, 0x30, 0x50, 0x10, 0x10, 0x10, 0x7c, 0x00	// 1
	.byte 0x38, 0x44, 0x04, 0x08, 0x10, 0x20, 0x7c, 0x00	// 2
	.byte 0x38, 0x44, 0x04, 0x38, 0x04, 0x44, 0x38, 0x00	// 3
	.byte 0x48, 0x48, 0x48, 0x78, 0x08, 0x08, 0x08, 0x00	// 4
	.byte 0x7C, 0x40, 0x78, 0x04, 0x04, 0x44, 0x38, 0x00	// 5
	.byte 0x38, 0x40, 0x40, 0x78, 0x44, 0x44, 0x38, 0x00	// 6
	.byte 0x78, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x00	// 7
	.byte 0x38, 0x44, 0x44, 0x38, 0x44, 0x44, 0x38, 0x00	// 8
	.byte 0x38, 0x44, 0x44, 0x3C, 0x04, 0x44, 0x38, 0x00	// 9
.space (8*7) // leave space for punctuation
	.byte 0x30, 0x48, 0x84, 0x84, 0xFC, 0x84, 0x84, 0x00	// A
	.byte 0x78, 0x44, 0x44, 0x78, 0x44, 0x44, 0x78, 0x00	// B
	.byte 0x38, 0x44, 0x40, 0x40, 0x40, 0x44, 0x38, 0x00	// C
	.byte 0x78, 0x44, 0x44, 0x44, 0x44, 0x44, 0x78, 0x00	// D
	.byte 0x7c, 0x40, 0x40, 0x78, 0x40, 0x40, 0x7c, 0x00	// E
	.byte 0x7c, 0x40, 0x40, 0x78, 0x40, 0x40, 0x40, 0x00	// F
	.byte 0x3c, 0x40, 0x40, 0x5c, 0x44, 0x44, 0x38, 0x00	// G
	.byte 0x44, 0x44, 0x44, 0x7c, 0x44, 0x44, 0x44, 0x00	// H
	.byte 0x7c, 0x10, 0x10, 0x10, 0x10, 0x10, 0x7c, 0x00	// I
	.byte 0x3c, 0x08, 0x08, 0x08, 0x08, 0x48, 0x30, 0x00	// J
	.byte 0x44, 0x48, 0x50, 0x60, 0x50, 0x48, 0x44, 0x00	// K
	.byte 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x7c, 0x00	// L
	.byte 0x82, 0xc6, 0xaa, 0x92, 0x82, 0x82, 0x82, 0x00	// M
	.byte 0x82, 0xc2, 0xa2, 0x92, 0x8a, 0x86, 0x82, 0x00	// N
	.byte 0x3c, 0x42, 0x42, 0x42, 0x42, 0x42, 0x3c, 0x00	// O
	.byte 0x78, 0x44, 0x44, 0x78, 0x40, 0x40, 0x40, 0x00	// P
	.byte 0x3c, 0x42, 0x42, 0x42, 0x42, 0x3c, 0x07, 0x00	// Q
	.byte 0x78, 0x44, 0x44, 0x78, 0x50, 0x48, 0x44, 0x00	// R
	.byte 0x38, 0x44, 0x40, 0x38, 0x04, 0x44, 0x38, 0x00	// S
	.byte 0x7c, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x00	// T
	.byte 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x38, 0x00	// U
	.byte 0x82, 0x82, 0x44, 0x44, 0x28, 0x28, 0x10, 0x00	// V
	.byte 0x82, 0x82, 0x82, 0x92, 0xBA, 0x6C, 0x44, 0x00	// W
	.byte 0x82, 0x44, 0x28, 0x10, 0x28, 0x44, 0x82, 0x00	// X
	.byte 0x82, 0x44, 0x28, 0x10, 0x10, 0x10, 0x10, 0x00	// Y
	.byte 0xFE, 0x04, 0x08, 0x10, 0x20, 0x40, 0xFE, 0x00	// Z
.space (8*6) // leave space for punctuation
	.byte 0x30, 0x48, 0x84, 0x84, 0xFC, 0x84, 0x84, 0x00	// A
	.byte 0x78, 0x44, 0x44, 0x78, 0x44, 0x44, 0x78, 0x00	// B
	.byte 0x38, 0x44, 0x40, 0x40, 0x40, 0x44, 0x38, 0x00	// C
	.byte 0x78, 0x44, 0x44, 0x44, 0x44, 0x44, 0x78, 0x00	// D
	.byte 0x7c, 0x40, 0x40, 0x78, 0x40, 0x40, 0x7c, 0x00	// E
	.byte 0x7c, 0x40, 0x40, 0x78, 0x40, 0x40, 0x40, 0x00	// F
	.byte 0x3c, 0x40, 0x40, 0x5c, 0x44, 0x44, 0x38, 0x00	// G
	.byte 0x44, 0x44, 0x44, 0x7c, 0x44, 0x44, 0x44, 0x00	// H
	.byte 0x7c, 0x10, 0x10, 0x10, 0x10, 0x10, 0x7c, 0x00	// I
	.byte 0x3c, 0x08, 0x08, 0x08, 0x08, 0x48, 0x30, 0x00	// J
	.byte 0x44, 0x48, 0x50, 0x60, 0x50, 0x48, 0x44, 0x00	// K
	.byte 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x7c, 0x00	// L
	.byte 0x82, 0xc6, 0xaa, 0x92, 0x82, 0x82, 0x82, 0x00	// M
	.byte 0x82, 0xc2, 0xa2, 0x92, 0x8a, 0x86, 0x82, 0x00	// N
	.byte 0x3c, 0x42, 0x42, 0x42, 0x42, 0x42, 0x3c, 0x00	// O
	.byte 0x78, 0x44, 0x44, 0x78, 0x40, 0x40, 0x40, 0x00	// P
	.byte 0x3c, 0x42, 0x42, 0x42, 0x42, 0x3c, 0x07, 0x00	// Q
	.byte 0x78, 0x44, 0x44, 0x78, 0x50, 0x48, 0x44, 0x00	// R
	.byte 0x38, 0x44, 0x40, 0x38, 0x04, 0x44, 0x38, 0x00	// S
	.byte 0x7c, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x00	// T
	.byte 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x38, 0x00	// U
	.byte 0x82, 0x82, 0x44, 0x44, 0x28, 0x28, 0x10, 0x00	// V
	.byte 0x82, 0x82, 0x82, 0x92, 0xBA, 0x6C, 0x44, 0x00	// W
	.byte 0x82, 0x44, 0x28, 0x10, 0x28, 0x44, 0x82, 0x00	// X
	.byte 0x82, 0x44, 0x28, 0x10, 0x10, 0x10, 0x10, 0x00	// Y
	.byte 0xFE, 0x04, 0x08, 0x10, 0x20, 0x40, 0xFE, 0x00	// Z
//------------------------------------------------------------------
