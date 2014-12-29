.section ".text"

.global interrupt_vector
.global init_arm_timer

.equ  LOAD,       0x00
.equ  CONTROL,    0x08
.equ  IRQ_CLEAR,  0x0C

.equ  RPI_ARMTIMER_CTRL_23BIT,         0x2
.equ  RPI_ARMTIMER_CTRL_PRESCALE_256,  0x8
.equ  RPI_ARMTIMER_CTRL_INT_ENABLE,    0x20
.equ  RPI_ARMTIMER_CTRL_ENABLE,        0x80

.equ  RPI_BASIC_IRQS,              0x18
.equ  RPI_BASIC_ARM_TIMER_IRQ,     0x01


ARM_TIMER_BASE:                 .word 0x2000B400
RPI_INTERRUPT_CONTROLLER_BASE:  .word   0x2000B200


//------------------------------------------------------------------
init_arm_timer:
    push {r0, r1}
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

    mov r1, #256
    add r1, #144        //Results in 390, which is about 10Hz

    str r1, [r0, #LOAD]
    //
    // Control settings
    //
    mov r1, #0
    orr r1, #(RPI_ARMTIMER_CTRL_23BIT | RPI_ARMTIMER_CTRL_ENABLE | RPI_ARMTIMER_CTRL_INT_ENABLE | RPI_ARMTIMER_CTRL_PRESCALE_256)
    str r1, [r0, #CONTROL]
    pop {r0, r1}
    mov pc, lr

//------------------------------------------------------------------
count:  .word 0x1

interrupt_vector:
    push    {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, lr}
    
    //
    // First clear the IRQ flag
    //
    ldr r0, ARM_TIMER_BASE
    mov r1, #1
    str r1, [r0, #IRQ_CLEAR]
    //
    // Convert the count to a bit pattern
    //
    ldr r6, count
    mov r3, #1    // r3 hold the current bit mask 
bit_loop:
    and r4, r6, r3// Apply the mask to the count in r6, answer in r4
    //
    // Set r2 to the bit number
    //
    clz r2, r3        // Leading zeros = 31 for bit 1, 30 for 2 etc
    sub r2, #19       // Subtract 19 to get the LED number
    //
    // If the bit is set then turn on the right LED, otherwise turn it off
    //
    cmp r4, #0
    beq bit_is_zero
    //
    // Turn the LED on (LED number is in r2)
    //
    bl gert_led_on
    b next_bit
    //
    // If the bit is zero then turn the LED off
    //
bit_is_zero:
    bl gert_led_off
next_bit:
    lsl r3, #1
    cmp r3, #(1<<12)
    bne bit_loop
    //
    // Increment the count and store it for next time
    //
    add r6, #1
    str r6, count
    //
    // Return
    //
    ldm     sp!, {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, ip, pc}^
//------------------------------------------------------------------
