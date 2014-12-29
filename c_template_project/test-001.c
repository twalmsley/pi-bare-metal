#include <string.h>
#include <stdlib.h>

#include "rpi-gpio.h"
#include "rpi-armtimer.h"
#include "rpi-systimer.h"
#include "rpi-interrupts.h"

/** Main function - we'll never return from here */
void kernel_main( unsigned int r0, unsigned int r1, unsigned int atags )
{
    /* Write 1 to the GPIO16 init nibble in the Function Select 1 GPIO
       peripheral register to enable GPIO16 as an output */
    RPI_GetGpio()->GPFSEL0 |= (1 << 21) | (1 << 24) | (1 << 27);
    RPI_GetGpio()->GPFSEL1 |= (1<< 0) | (1 << 3) | (1 << 18) | (1 << 21) | (1 << 24);
    RPI_GetGpio()->GPFSEL2 |= (1<< 21) | (1 << 6) | (1 << 9)  | (1 << 12) | (1 << 15);

    /* Enable the timer interrupt IRQ */
    RPI_GetIrqController()->Enable_Basic_IRQs = RPI_BASIC_ARM_TIMER_IRQ;

    /* Setup the system timer interrupt */
    /* Timer frequency = Clk/256 * 0x400 */
    //RPI_GetArmTimer()->Load = 3900;// 1MHz/256/3900 ~= 1Hz
    //RPI_GetArmTimer()->Load = 390;// 1MHz/256/390 ~= 10Hz
    RPI_GetArmTimer()->Load = 39;// 1MHz/256/39 ~= 100Hz

    /* Setup the ARM Timer */
    RPI_GetArmTimer()->Control =
            RPI_ARMTIMER_CTRL_23BIT |
            RPI_ARMTIMER_CTRL_ENABLE |
            RPI_ARMTIMER_CTRL_INT_ENABLE |
            RPI_ARMTIMER_CTRL_PRESCALE_256;

    RPI_GetGpio()->GPSET0 = (1<<10);
    RPI_GetGpio()->GPCLR0 = (1<<16);
    /* Enable interrupts! */
    _enable_interrupts();

    while(1);// spin
}
