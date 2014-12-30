.section ".text.startup"

.include "../lib/constants.h"

.global _start

.extern heap_init
.extern heap_alloc_buffer
.extern scr_init
.extern scr_init_frame
.extern scr_set_colours
.extern SCR_FB_POINTER
.extern pseud_rand
.extern pseud_rand_seeds

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

// Setup Frame Buffer
.equ SCREEN_X,       640
.equ SCREEN_Y,       480
.equ BITS_PER_PIXEL, 32

    //
    // Use the heap allocation routines to allocate a life_buffer
    //
    bl heap_init
    mov r0, #(SCREEN_X*SCREEN_Y*4)
    bl heap_alloc_buffer
    str r0, life_buffer_ptr

    bl scr_init
    //
    // Set up the frame
    //
    ldr r0, foreground
    ldr r1, background
	bl scr_set_colours
    bl scr_init_frame

	mov r0, #0x000000AA
	mov r1, #0x0000AA00
	mov r2, #0x00AA0000
	mov r3, #0xAA000000
	bl pseud_rand_seeds
    bl seed_life

next_frame:
    bl update_frame_buffer

    bl next_generation
    b next_frame

//-------------------------------------------------------------------------------------------------
// Init life - use some fixed algorithm as the starting point
//-------------------------------------------------------------------------------------------------
seed_life:
    push {r4, r5, lr}

    ldr r3, foreground
    ldr r5, background

    orr r3, #0xFF000000
    orr r5, #0xFF000000
    ldr r0,life_buffer_ptr // R0 = Life Buffer Pointer

    mov r1, #(SCREEN_X * SCREEN_Y)
seed_loop:

	push {r0, r1, r2, r3}
	bl pseud_rand
	mov r4, r0
	pop {r0, r1, r2, r3}

    tst r4, #1
    strne r3, [r0]
    streq r5, [r0]

    add r0, #4
    subs r1, #1
    bne seed_loop

    pop {r4, r5, pc}
//-------------------------------------------------------------------------------------------------
// Update the frame buffer with the current state of the life_buffer
//-------------------------------------------------------------------------------------------------
update_frame_buffer:
    push {r4, r5, lr}

    ldr r0,=SCR_FB_POINTER // R0 = Frame Buffer Pointer
    ldr r0, [r0]
    ldr r1,life_buffer_ptr // R0 = Life Buffer Pointer
    mov r2, #(SCREEN_X * SCREEN_Y)

	bl util_block_transfer
    //
    // Return
    //
    pop {r4, r5, pc}
//-------------------------------------------------------------------------------------------------
// Use the Game of Life rules to calculate the next generation
//-------------------------------------------------------------------------------------------------
next_generation:
    push {lr}

    ldr r0,life_buffer_ptr // R0 = Life Buffer Pointer
    ldr r3,=SCR_FB_POINTER // R0 = Frame Buffer Pointer
    ldr r3, [r3]

    mov r1, #(SCREEN_X * SCREEN_Y)
gen_loop:

    bl process_cell

    add r0, #4
    add r3, #4

    subs r1, #1
    bne gen_loop

    pop {pc}
//-------------------------------------------------------------------------------------------------
// Process the current cell - use the frame buffer to check neighbours and update the life buffer
// r0 = pointer to cell in life_buffer
// r1 = Y
// r2 = X
// r3 = pointer to cell in Frame Buffer
//
//      123
//      4X5
//      678
//-------------------------------------------------------------------------------------------------
process_cell:
    push {r4, r5, r6, r7, lr}
    //
    // Count the 'living' cells around the current frame_buffer cell
    //
    ldr r6, foreground
    ldr r7, background
    orr r6, #0xFF000000
    orr r7, #0xFF000000

    mov r4, #0
    ldr r5, [r3, #-(4*SCREEN_X)-4]   // cell 1
    cmp r5, r6
    addeq r4, #1

    ldr r5, [r3, #-(4*SCREEN_X)]   // cell 2
    cmp r5, r6
    addeq r4, #1

    ldr r5, [r3, #-(4*SCREEN_X)+4]   // cell 3
    cmp r5, r6
    addeq r4, #1

    ldr r5, [r3, #-4]   // cell 4
    cmp r5, r6
    addeq r4, #1

    ldr r5, [r3, #4]   // cell 5
    cmp r5, r6
    addeq r4, #1

    ldr r5, [r3, #(4*SCREEN_X)-4]   // cell 6
    cmp r5, r6
    addeq r4, #1

    ldr r5, [r3, #(4*SCREEN_X)]   // cell 7
    cmp r5, r6
    addeq r4, #1

    ldr r5, [r3, #(4*SCREEN_X)+4]   // cell 8
    cmp r5, r6
    addeq r4, #1
    //
    // r4 now hold the neighbour count (with errors due to screen edges not wrapping)
    // r5 will hold the current cell value
    //
    ldr r5, [r3]
    teq r5, r6
    beq alive
dead:
    //
    // Create a new living cell and return
    //
    cmp r4, #3
    streq r6, [r0]
    beq process_cell_exit

alive:
    cmp r4, #2
    strlt r7, [r0]

    cmp r4, #3
    strgt r7, [r0]
process_cell_exit:
    pop {r4, r5, r6, r7, pc}
//-------------------------------------------------------------------------------------------------
.pool
background: .word 0xFF000080
foreground: .word 0xFFFFFFFF

life_buffer_ptr: .word 0x0

//------------------------------------------------------------------
