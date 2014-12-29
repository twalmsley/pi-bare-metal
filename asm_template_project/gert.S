.section ".text"

.include "constants.h"

RPI_GPIO_BASE: .word             0x20200000

.global gert_init_leds
.global gert_init_buttons
.global gert_led_on
.global gert_led_off
.global gert_button_state

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
// No parameters - changes r0 and r1
//
// No subroutine calls
//------------------------------------------------------------------
gert_init_leds:
    //
    // Set the GPIO SEL registers for the Gertboard LEDs as outputs
    //
    ldr r0, RPI_GPIO_BASE
    mov r1, #0
    orr r1, r1, #(1<<21) | (1<<24) | (1<<27)
    str r1, [r0,#RPI_GPFSEL0]

    mov r1, #0
    orr r1, r1, #(1<<18)|(1<<21)|(1<<24)
    orr r1, r1, #(1<<0)|(1<<3)
    str r1, [r0,#RPI_GPFSEL1]

    mov r1, #0
    orr r1, r1, #(1<<21)
    orr r1, r1, #(1<<6)
    str r1, [r0,#RPI_GPFSEL2]
    mov pc, lr

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
    lslle r0, #2
    ldrle r0, [r1, r0]
    movle pc, lr

    mov r0, #0 // Default to zero
    mov pc, lr

//------------------------------------------------------------------
// Led num is in r0 (1 to 12)
//------------------------------------------------------------------
gert_led_on:
    stmdb sp!, {lr}
    bl gert_led_num_to_bit // Convert value r0 to an LED bit mask
    ldr r1, RPI_GPIO_BASE
    str r0, [r1, #RPI_GPSET0]
    ldmia sp!, {pc}

//------------------------------------------------------------------
// Led num is in r0 (1 to 12)
//------------------------------------------------------------------
gert_led_off:
    stmdb sp!, {lr}
    bl gert_led_num_to_bit // Convert value r0 to an LED bit mask
    ldr r1, RPI_GPIO_BASE
    str r0, [r1, #RPI_GPCLR0]
    ldmia sp!, {pc}
//------------------------------------------------------------------
gert_button_state:
    ldr r1, RPI_GPIO_BASE
    ldr r0, [r1, #RPI_GPLEV0]
    lsr r0, #23
    and r0, #7
    mov pc, lr
