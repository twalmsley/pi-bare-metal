.section ".text.startup"

.include "../lib/constants.h"

.global _start

.extern scr_init
.extern scr_init_frame
.extern scr_set_colours
.extern print_str
.extern print_int
.extern scr_set_xy
.extern scr_draw_sprite32
.extern scr_draw_sprite16
.extern gfx_rect
.extern gfx_fill_rect

.arm

_start:

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

	mov r0, #(1<<25)
	bl util_r0_delay	// Delay to allow the HMDI ouput to come on

//
// Set up the colours
//
	mov r0, #0x000000FF
	orr r0, #0xFF000000
    ldr r1, background
	bl scr_set_colours

//
// draw an array of sprites across the screen
//
	mov r5, #0
	mov r4, #0

inner_loop:
	mov r0, r4
	mov r1, r5
	bl scr_set_xy

	ldr r0, =sprite16_ptr
	bl scr_draw_sprite16

	add r4, #16
	cmp r4, #640-16
	ble inner_loop

	mov r5, #32
	mov r4, #0

//
// Set up the colours
//
	mov r0, #0x0000FF00
	orr r0, #0xFF000000
    ldr r1, background
	bl scr_set_colours
inner_loop2:
	mov r0, r4
	mov r1, r5
	bl scr_set_xy

	ldr r0, =sprite32_ptr
	bl scr_draw_sprite32

	add r4, #32
	cmp r4, #640-32
	ble inner_loop2
//
// Set up the colours
//
	mov r0, #0x000000FF
	orr r0, #0xFF0000
	orr r0, #0xFF00
	orr r0, #0xFF000000
    ldr r1, background
	bl scr_set_colours
//
// Write some text
//
	mov r0, #0
	mov r1, #0
	bl scr_set_xy

	ldr r0, =msg1
	ldr r1, msg1_len
	bl print_str
//
// Draw a rectangle round the whole screen
//
	mov r0, #0
	mov r1, #0
	bl scr_set_xy

	mov r0, #640
	mov r1, #480
	bl gfx_rect// gfx_rect - draw a rectangle at the current coords of size x=r0, y=r1
//
// Draw a rectangle in the middle-ish screen
//
	mov r0, #100
	mov r1, #100
	bl scr_set_xy

	mov r0, #640-200
	mov r1, #480-200
	bl gfx_fill_rect// gfx_fill_rect - fill a rectangle at the current coords of size x=r0, y=r1
spin_loop:
	b spin_loop

//------------------------------------------------------------------
background:
	.word 0xFF404040
foreground:
	.word 0xFFFFFFFF

msg1:
	.string "0123456789\n"
.align
msg1_len:
	.word 11
msg2:
	.string "ABCDEFGHIJKLMNOPQRSTUVWXYZ\n"
.align
msg2_len:
	.word 27
msg3:
	.string "\n"
.align
msg3_len:
	.word 1

sprite32_ptr: // 32 words give a 32x32 pixel sprite
	.word 0b00000000000000000000000000000000
	.word 0b00000000011111111110000000000000
	.word 0b00000000111111111111000000000000
	.word 0b00000001111111111111100000000000
	.word 0b00000011111111111111110000000000
	.word 0b00000111100001110000111000000000
	.word 0b00000111000000100000011000000000
	.word 0b00000111000001110000011000000000
	.word 0b00000111100011111000111000000000
	.word 0b00000011111111111111110000000000
	.word 0b00000001111110101111100000000000
	.word 0b00000000111111111111000000000000
	.word 0b00000000011111111110000000000000
	.word 0b00000000010101010110000000000000
	.word 0b00000000010101010110000000000000
	.word 0b00000000011111111110000000000000
	.word 0b00000000000001100000000000000000
	.word 0b00000000000001100000000000000000
	.word 0b00001111111111111111111110000000
	.word 0b00000000000001100000000000000000
	.word 0b00011111111111111111111111000000
	.word 0b00000000000001100000000000000000
	.word 0b00111111111111111111111111100000
	.word 0b00000000000001100000000000000000
	.word 0b00000111111111111111111110000000
	.word 0b00000000000001100000000000000000
	.word 0b00000000011111111111000000000000
	.word 0b00000001110001110001110000000000
	.word 0b00000001110001110001110000000000
	.word 0b00000000111111111111100000000000
	.word 0b00000000011111111111000000000000
	.word 0b00000000000000000000000000000000

sprite16_ptr: // 16 shorts give a 16x16 pixel sprite
	.hword 0b0011000000110000
	.hword 0b0000100001000000
	.hword 0b0000111111100000
	.hword 0b0001111111100000
	.hword 0b0001100100110000
	.hword 0b0011000100010000
	.hword 0b0011000100010000
	.hword 0b0001101110110000
	.hword 0b0001111011100000
	.hword 0b0000110101100000
	.hword 0b0000111111000000
	.hword 0b0000011111000000
	.hword 0b0000010101000000
	.hword 0b0000010101000000
	.hword 0b0000011111000000
	.hword 0b0000000000000000

//------------------------------------------------------------------
