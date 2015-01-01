.section ".text"

.include "constants.h"

RPI_GPIO_BASE: .word             0x20200000

.global gert_init_leds
.global gert_init_buttons
.global gert_led_on
.global gert_led_off
.global gert_button_state

//------------------------------------------------------------------
// Used for convert an LED index (1-12) to the correct bit mask for
// GPFSET0 and GPFCLR0
//------------------------------------------------------------------
gert_led_table:
    .word 0x00    // dummy value for easier indexing
    .word (1<<25)
    .word (1<<24)
    .word (1<<23)
    .word (1<<22)
    .word (1<<27)
    .word (1<<18)
    .word (1<<17)
    .word (1<<11)
    .word (1<<10)
    .word (1<<9)
    .word (1<<8)
    .word (1<<7)
//------------------------------------------------------------------
// Used for convert an LED index (1-12) to a GPIO number
// Can also be used for buttons since they then would not be used
// as LED outputs
//------------------------------------------------------------------
gert_led_gpio_num_table:
    .word 0    // dummy value for easier indexing
    .word 25   // LED1 or button1
    .word 24   // LED2 or button2
    .word 23   // LED3 or button3
    .word 22   // LED4
    .word 27   // LED5
    .word 18   // LED6
    .word 17   // LED7
    .word 11   // LED8
    .word 10   // LED9
    .word 9    // LED10
    .word 8    // LED11
    .word 7    // LED12
//------------------------------------------------------------------
// No parameters, but changes r1 and r2
//
// Calls a delay routine
//------------------------------------------------------------------
gert_init_buttons:
    push {lr}
    ldr r2, RPI_GPIO_BASE
    mov r1, #2
    str r1, [r2, #RPI_GPPUD]

    //
    // Pause to allow the change to take effect
    //
    mov r0, #200
    bl util_r0_delay

    mov r1, #(1<<23) | (1<<24) | (1<<25)
    str r1, [r2, #RPI_GPPUDCLK0]

    //
    // Pause to allow the change to take effect
    //
    mov r0, #200
    bl util_r0_delay

    mov r1, #0
    str r1, [r2, #RPI_GPPUD]
    str r1, [r2, #RPI_GPPUDCLK0]

    pop {pc}
//------------------------------------------------------------------
// Params: r0 needs bits 1 to 12 set to indicate which LEDs should
// be enabled. This is stored in gert_enabled_leds for use by other
// functions.
//------------------------------------------------------------------
gert_init_leds:
    push {r4, r5, r6, r7, lr}

    str r0, gert_enabled_leds       // store r0 for later reference

    //
    // Iterate bits 1 to 12 and if set then convert the bit number to
    // a GPFSEL value and set it as an output
    //
    //  r5 is used for GPFSEL0
    //  r6 is used for GPFSEL1
    //  r7 is used for GPFSEL2
    //
    mov r5, #0
    mov r6, #0
    mov r7, #0

    mov r1, #1      // The LED counter
    mov r2, #1      // The r0 bit mask
gert_init_leds_loop:
    lsl r2, #1
    tst r0, r2
    blne gert_init_leds_enable_led   // Bit is set so enable the LED

    cmp r1, #12
    addlt r1, #1
    blt gert_init_leds_loop
    //
    // Now update the GPFSELn registers
    //
    ldr r0, RPI_GPIO_BASE
    str r5, [r0, #RPI_GPFSEL0]
    str r6, [r0, #RPI_GPFSEL1]
    str r7, [r0, #RPI_GPFSEL2]
    pop {r4, r5, r6, r7, pc}                // Finished, so return

gert_init_leds_enable_led:
    push {lr}
    //
    // (r1 contains the LED number from 1 to 12)
    // Get the GPIO number from the lookup table
    //
    ldr r4, =gert_led_gpio_num_table
    ldr r4, [r4, r1, LSL #2]
    //
    // Check which GPFSELn to use
    //
    cmp r4, #9
    bgt gert_led_init_skip1
    //
    // The bit is in GPFSEL0 so update r5
    //
    add r4, r4, r4, LSL #1      // Multiply r4 by 3
    mov r3, #1
    lsl r3, r4
    orr r5, r3
    pop {pc}   // Jump back to the main loop

gert_led_init_skip1:
    cmp r4, #19
    bgt gert_led_init_skip2
    //
    // The bit is in GPFSEL1 so update r6
    //
    sub r4, #10                 // Adjust r4 so the next line finds the right bit
    add r4, r4, r4, LSL #1      // Multiply r4 by 3
    mov r3, #1
    lsl r3, r4
    orr r6, r3
    pop {pc}   // Jump back to the main loop

gert_led_init_skip2:
    cmp r4, #29
    popgt {pc} // Too big for a gertboard LED so just return
    //
    // The bit is in GPFSEL2 so update r7
    //
    sub r4, #20                 // Adjust r4 so the next line finds the right bit
    add r4, r4, r4, LSL #1      // Multiply r4 by 3
    mov r3, #1
    lsl r3, r4
    orr r7, r3
    pop {pc}

gert_enabled_leds:  .word 0x0

//------------------------------------------------------------------
// param r0 = LED number from 1 to 12
// result r0 = bit mask for GPIO of the specified LED
//------------------------------------------------------------------
gert_led_num_to_bit:
    //
    // Convert an LED num (1 to 12) to a bit mask in r1
    //
    CMP r0, #12
    ldrle r1, =gert_led_table
    ldrle r0, [r1, r0, lsl #2]
    movle pc, lr

    mov r0, #0 // Default to zero
    mov pc, lr

//------------------------------------------------------------------
// Led num is in r0 (1 to 12)
//------------------------------------------------------------------
gert_led_on:
    push {lr}
    //
    // First check that the LED is enabled
    //
    ldr r1, gert_enabled_leds
    mov r2, #1
    tst r1, r2, lsl r0
    popeq {pc}    // Not enabled, so just return
    //
    // Its enabled, so turn it on
    //
    bl gert_led_num_to_bit // Convert value r0 to an LED bit mask
    ldr r1, RPI_GPIO_BASE
    str r0, [r1, #RPI_GPSET0]
    pop {pc}

//------------------------------------------------------------------
// Led num is in r0 (1 to 12)
//------------------------------------------------------------------
gert_led_off:
    push {lr}
    //
    // First check that the LED is enabled
    //
    ldr r1, gert_enabled_leds
    mov r2, #1
    tst r1, r2, lsl r0
    popeq {pc}    // Not enabled, so just return
    //
    // Its enabled, so turn it off
    //
    bl gert_led_num_to_bit // Convert value r0 to an LED bit mask
    ldr r1, RPI_GPIO_BASE
    str r0, [r1, #RPI_GPCLR0]
    ldmia sp!, {pc}
//------------------------------------------------------------------
// Return the gert button state in r0
//------------------------------------------------------------------
gert_button_state:
    ldr r1, RPI_GPIO_BASE
    ldr r0, [r1, #RPI_GPLEV0]
    lsr r0, #23
    and r0, #7
    mov pc, lr
