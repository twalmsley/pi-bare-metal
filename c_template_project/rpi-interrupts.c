
#include <stdint.h>
#include <stdbool.h>

#include "rpi-armtimer.h"
#include "rpi-base.h"
#include "rpi-gpio.h"
#include "rpi-interrupts.h"

/** @brief The BCM2835 Interupt controller peripheral at it's base address */
static rpi_irq_controller_t* rpiIRQController =
        (rpi_irq_controller_t*)RPI_INTERRUPT_CONTROLLER_BASE;


/**
    @brief Return the IRQ Controller register set
*/
rpi_irq_controller_t* RPI_GetIrqController( void )
{
    return rpiIRQController;
}


/**
    @brief The Reset vector interrupt handler

    This can never be called, since an ARM core reset would also reset the
    GPU and therefore cause the GPU to start running code again until
    the ARM is handed control at the end of boot loading
*/
void __attribute__((interrupt("ABORT"))) reset_vector(void)
{

}

/**
    @brief The undefined instruction interrupt handler

    If an undefined intstruction is encountered, the CPU will start
    executing this function. Just trap here as a debug solution.
*/
void __attribute__((interrupt("UNDEF"))) undefined_instruction_vector(void)
{
    while( 1 )
    {
        /* Do Nothing! */
    }
}


/**
    @brief The supervisor call interrupt handler

    The CPU will start executing this function. Just trap here as a debug
    solution.
*/
void __attribute__((interrupt("SWI"))) software_interrupt_vector(void)
{
    while( 1 )
    {
        /* Do Nothing! */
    }
}


/**
    @brief The prefetch abort interrupt handler

    The CPU will start executing this function. Just trap here as a debug
    solution.
*/
void __attribute__((interrupt("ABORT"))) prefetch_abort_vector(void)
{

}


/**
    @brief The Data Abort interrupt handler

    The CPU will start executing this function. Just trap here as a debug
    solution.
*/
void __attribute__((interrupt("ABORT"))) data_abort_vector(void)
{

}


/**
    @brief The IRQ Interrupt handler

    This handler is run every time an interrupt source is triggered. It's
    up to the handler to determine the source of the interrupt and most
    importantly clear the interrupt flag so that the interrupt won't
    immediately put us back into the start of the handler again.
*/
void __attribute__((interrupt("IRQ"))) interrupt_vector(void)
{
    static int lit = 0;
    static int count = 1;

    /* Clear the ARM Timer interrupt - it's the only interrupt we have
       enabled, so we want don't have to work out which interrupt source
       caused us to interrupt */
    RPI_GetArmTimer()->IRQClear = 1;

    int val0 = 0;
  
    val0 |= ((count & 0x0001) << 7);// bit 0 = LED 12
    val0 |= ((count & 0x0002) << 7);// bit 1 = LED 11
    val0 |= ((count & 0x0004) << 7);// bit 2 = LED 10
    val0 |= ((count & 0x0008) << 7);// bit 3 = LED 9
    val0 |= ((count & 0x0010) << 7);// bit 4 = LED 8
    val0 |= ((count & 0x0020) << 12);// bit 5 = LED 7
    val0 |= ((count & 0x0040) << 12);// bit 6 = LED 6
    val0 |= ((count & 0x0080) << 20);// bit 7 = LED 5
    val0 |= ((count & 0x0100) << 14);// bit 8 = LED 4
    val0 |= ((count & 0x0200) << 14);// bit 9 = LED 3
    val0 |= ((count & 0x0400) << 14);// bit 10 = LED 2
    val0 |= ((count & 0x0800) << 14);// bit 11 = LED 1

    /* Flip the LED */
    if( lit )
    {
      lit = 0;
    }
    else
    {
      lit = 1;
    }
    val0 |= (lit<<16);
    RPI_GetGpio()->GPCLR0 = ~val0;
    RPI_GetGpio()->GPSET0 = val0;
    count++;
}


/**
    @brief The FIQ Interrupt Handler

    The FIQ handler can only be allocated to one interrupt source. The FIQ has
    a full CPU shadow register set. Upon entry to this function the CPU
    switches to the shadow register set so that there is no need to save
    registers before using them in the interrupt.

    In C you can't see the difference between the IRQ and the FIQ interrupt
    handlers except for the FIQ knowing it's source of interrupt as there can
    only be one source, but the prologue and epilogue code is quite different.
    It's much faster on the FIQ interrupt handler.

    The prologue is the code that the compiler inserts at the start of the
    function, if you like, think of the opening curly brace of the function as
    being the prologue code. For the FIQ interrupt handler this is nearly
    empty because the CPU has switched to a fresh set of registers, there's
    nothing we need to save.

    The epilogue is the code that the compiler inserts at the end of the
    function, if you like, think of the closing curly brace of the function as
    being the epilogue code. For the FIQ interrupt handler this is nearly
    empty because the CPU has switched to a fresh set of registers and so has
    not altered the main set of registers.
*/
void __attribute__((interrupt("FIQ"))) fast_interrupt_vector(void)
{

}
