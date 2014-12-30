.section ".text.interrupt"

.global interrupt_vector
.global init_arm_timer
.global init_gert_buttons_gpio_falling_edge
.global int_set_callback1
.global int_set_callback2
.global int_set_callback3
.global int_set_callback4

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

    mov r1, #4   // About 976.5Hz
    
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

interrupt_vector:
    push {r0-r12, lr}
    
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
    pop {r0-r12, lr}
	subs pc,r14,#4
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
	// Invoke the callbacks if they aren't null
	//
	ldr r0, int_callback1
	cmp r0, #0
	movne lr, pc
	movne pc, r0

	ldr r0, int_callback2
	cmp r0, #0
	movne lr, pc
	movne pc, r0

	ldr r0, int_callback3
	cmp r0, #0
	movne lr, pc
	movne pc, r0

	ldr r0, int_callback4
	cmp r0, #0
	movne lr, pc
	movne pc, r0

    pop {pc}
//-------------------------------------------------------------
int_callback1:
	.word 0
int_callback2:
	.word 0	
int_callback3:
	.word 0	
int_callback4:
	.word 0	
//-------------------------------------------------------------
// Store a callback function - address is in r0, must not be null
//-------------------------------------------------------------
int_set_callback1:
	str r0, int_callback1
	mov pc, lr

int_set_callback2:
	str r0, int_callback2
	mov pc, lr

int_set_callback3:
	str r0, int_callback3
	mov pc, lr

int_set_callback4:
	str r0, int_callback4
	mov pc, lr
//-------------------------------------------------------------

