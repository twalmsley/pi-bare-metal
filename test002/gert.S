.section ".text"

.equ    RPI_GPFSEL0,      0x00
.equ    RPI_GPFSEL1,      0x04
.equ    RPI_GPFSEL2,      0x08
.equ    RPI_GPFSEL3,      0x0c
.equ    RPI_GPFSEL4,      0x10
.equ    RPI_GPFSEL5,      0x14
.equ    RPI_GPSET0,       0x1C
.equ    RPI_GPSET1,       0x20
.equ    RPI_GPCLR0,       0x28
.equ    RPI_GPCLR1,       0x2C
.equ    RPI_GPLEV0,       0x34
.equ    RPI_GPLEV1,       0x38

RPI_GPIO_BASE: .word             0x20200000

.global gert_init_leds
.global gert_led_on
.global gert_led_off

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
    orr r1, r1, #(1<<21)|(1<<15)
    orr r1, r1, #(1<<6)|(1<<9)|(1<<12)
    str r1, [r0,#RPI_GPFSEL2]
    mov     pc, lr

//------------------------------------------------------------------
gert_led_num_to_bit:
    //
    // Convert an LED num (1 to 12) to a bit mask in r1
    //
    CMP r2, #1
    ITT  EQ
    moveq r1, #(1<<25)
    beq gert_led_num_to_bit_exit

    CMP r2, #2
    ITT  EQ
    moveq r1, #(1<<24)
    beq gert_led_num_to_bit_exit

    CMP r2, #3
    ITT  EQ
    moveq r1, #(1<<23)
    beq gert_led_num_to_bit_exit

    CMP r2, #4
    ITT  EQ
    moveq r1, #(1<<22)
    beq gert_led_num_to_bit_exit

    CMP r2, #5
    ITT  EQ
    moveq r1, #(1<<27)
    beq gert_led_num_to_bit_exit

    CMP r2, #6
    ITT  EQ
    moveq r1, #(1<<18)
    beq gert_led_num_to_bit_exit

    CMP r2, #7
    ITT  EQ
    moveq r1, #(1<<17)
    beq gert_led_num_to_bit_exit

    CMP r2, #8
    ITT  EQ
    moveq r1, #(1<<11)
    beq gert_led_num_to_bit_exit

    CMP r2, #9
    ITT  EQ
    moveq r1, #(1<<10)
    beq gert_led_num_to_bit_exit

    CMP r2, #10
    ITT  EQ
    moveq r1, #(1<<9)
    beq gert_led_num_to_bit_exit

    CMP r2, #11
    ITT  EQ
    moveq r1, #(1<<8)
    beq gert_led_num_to_bit_exit

    CMP r2, #12
    ITT  EQ
    moveq r1, #(1<<7)
    beq gert_led_num_to_bit_exit

    mov r1, #0 // Default to zero
gert_led_num_to_bit_exit:
    mov pc, lr

//------------------------------------------------------------------
gert_led_on:
    push {r0, r1, lr}
    bl gert_led_num_to_bit // Convert value r2 to an LED bit mask
    ldr r0, RPI_GPIO_BASE
    str r1, [r0, #RPI_GPSET0]
    pop {r0, r1, lr}
    mov     pc, lr

//------------------------------------------------------------------
gert_led_off:
    push {r0, r1, lr}
    bl gert_led_num_to_bit // Convert value r2 to an LED bit mask
    ldr r0, RPI_GPIO_BASE
    str r1, [r0, #RPI_GPCLR0]
    pop {r0, r1, lr}
    mov     pc, lr
//------------------------------------------------------------------
