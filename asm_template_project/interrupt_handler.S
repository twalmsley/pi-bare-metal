.section ".text.interrupt"

.global interrupt_vector
.global init_arm_timer

.include "constants.h"

ARM_TIMER_BASE:                 .word 0x2000B400
RPI_INTERRUPT_CONTROLLER_BASE:  .word   0x2000B200


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
    bne arm_timer_interrupt_pending

    b exit_interrupt
    //
    // First clear the IRQ flag
    //
arm_timer_interrupt_pending:
    ldr r2, ARM_TIMER_BASE
    mov r1, #1
    str r1, [r2, #IRQ_CLEAR]
    //
    //
    ldr r0, count
    ldr r3, light
    mov r4, r0
    tst r3,r3
    beq switch_off
    bl gert_led_on
    mov r3, #0
    str r3, light
    b exit_interrupt
switch_off:
    bl gert_led_off
    mov r3, #1
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
    moveq r0, #0
    streq r0, count_up

    cmp r4, #3
    moveq r4, #4
    moveq r0, #1
    streq r0, count_up

    str r4, count
    //
    // Return
    //
exit_interrupt:
    ldm     sp!, {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, pc}^
//------------------------------------------------------------------
