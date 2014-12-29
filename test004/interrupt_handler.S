.section ".text.interrupt"

.global interrupt_vector
.global init_arm_timer
.global init_gert_buttons_gpio_falling_edge

.include "constants.h"

GPIO_BASE:                      .word 0x20200000
ARM_TIMER_BASE:                 .word 0x2000B400
RPI_INTERRUPT_CONTROLLER_BASE:  .word 0x2000B200


//------------------------------------------------------------------
// No params, changes r0 and r1
//------------------------------------------------------------------
init_arm_timer:
    //
    // Enable basic interrupts
    //
    ldr r0, RPI_INTERRUPT_CONTROLLER_BASE
    mov r1, #RPI_BASIC_ARM_TIMER_IRQ
    str r1, [r0, #RPI_BASIC_IRQS]
    //
    // Set up the timer control regs
    //
    ldr r0, ARM_TIMER_BASE

    mov r1, #39   // About 100Hz

    str r1, [r0, #LOAD]
    //
    // Control settings
    //
    mov r1, #0
    orr r1, #(RPI_ARMTIMER_CTRL_23BIT | RPI_ARMTIMER_CTRL_ENABLE | RPI_ARMTIMER_CTRL_INT_ENABLE | RPI_ARMTIMER_CTRL_PRESCALE_256)
    str r1, [r0, #CONTROL]
    mov pc, lr

//------------------------------------------------------------------
// Initialise the gpio interrupts for the gert buttons on pins 23,
// 24 and 25 - just the falling edges are needed.
//------------------------------------------------------------------
init_gert_buttons_gpio_falling_edge:
    ldr r0, GPIO_BASE
    mov r1, #(1<<25)|(1<<24)|(1<<23)
    str r1, [r0, #RPI_GPFEN0]
    mov pc, lr
//------------------------------------------------------------------
// The interrupt handler - needs to check which interrupt occurred
// and jump to the appropriate handler.
//------------------------------------------------------------------
count:      .word 0x4       // The index of the current LED on the gertboard
light:      .word 0x1       // 1=light the LED on the next interrupt, 0=turn it off
count_up:   .word 0x1       // 1=count up, 0=count down - gives a left/right chase effect

interrupt_vector:
    stmdb sp!, {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, lr}
    
    //
    // Check which interrupt occurred and branch to the right part of the code,
    // otherwise branch to the exit point
    //
    ldr r0, RPI_INTERRUPT_CONTROLLER_BASE
    ldr r0, [r0, #RPI_BASIC_IRQ_PENDING_REG]

    tst r0, #RPI_BASIC_ARM_TIMER_IRQ
    blne arm_timer_interrupt_pending

    ldr r0, [r0, #RPI_GPUINTPENDING2]
    tst r0, #RPI_GPIO_INT_0
    blne arm_gpio_interrupt_pending  // The docs say only bank 0 is on the Pi expansion connector, so I ignore the others
    //
    // Return
    //
exit_interrupt:
    ldm     sp!, {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, pc}^
//------------------------------------------------------------------

//--------------------------
arm_gpio_interrupt_pending:
//--------------------------
    push {lr}
    //
    // Check for the button on GPIO25 and reset the LED counter if it had an event
    //
    ldr r0, GPIO_BASE
    ldr r1, [r0, #RPI_GPEDS0]

    tst r1, #(1<<25)
    blne handle_button_1

    tst r1, #(1<<24)
    blne handle_button_2

    tst r1, #(1<<23)
    blne handle_button_3

    //
    // Clear the flags for the buttons - we may miss an interrupt but the user will press again
    //
    ldr r0, GPIO_BASE
    mov r1, #(1<<25)|(1<<24)|(1<<23)
    str r1, [r0, #RPI_GPEDS0]
    pop {pc}

//--------------------------
handle_button_1:
//--------------------------
    mov pc, lr

//--------------------------
handle_button_2:
//--------------------------
    mov pc, lr

//--------------------------
handle_button_3:
//--------------------------
    mov pc, lr

//--------------------------
arm_timer_interrupt_pending:
//--------------------------
    push {lr}
    //
    // First clear the IRQ flag
    //
    ldr r2, ARM_TIMER_BASE
    mov r1, #1
    str r1, [r2, #IRQ_CLEAR]
    //
    ldr r0, count
    ldr r3, light
    mov r4, r0

    tst r3,r3
    beq switch_off
switch_on:
    bl gert_led_on
    mov r3, #0      // Use a flag to indicate switch off next time
    str r3, light
    pop {pc}

switch_off:
    bl gert_led_off
    mov r3, #1      // Use a flag to indicate switch on next time
    str r3, light
    //
    // Increment or decrement the count and store it for next time
    //
    ldr r0, count_up
    tst r0, r0
    subeq r4, #1
    addne r4, #1

    cmp r4, #13
    moveq r4, #12
    moveq r0, #0            // Change the count direction
    streq r0, count_up

    cmp r4, #3
    moveq r4, #4
    moveq r0, #1            // Change the count direction
    streq r0, count_up

    str r4, count
    pop {pc}
//-------------------------------------------------------------
