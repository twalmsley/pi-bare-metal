
.equ    RPI_GPFSEL0,                      0x00
.equ    RPI_GPFSEL1,                      0x04
.equ    RPI_GPFSEL2,                      0x08
.equ    RPI_GPFSEL3,                      0x0c
.equ    RPI_GPFSEL4,                      0x10
.equ    RPI_GPFSEL5,                      0x14
.equ    RPI_GPSET0,                       0x1C
.equ    RPI_GPSET1,                       0x20
.equ    RPI_GPCLR0,                       0x28
.equ    RPI_GPCLR1,                       0x2C
.equ    RPI_GPLEV0,                       0x34
.equ    RPI_GPLEV1,                       0x38
.equ    RPI_GPEDS0,                       0x40
.equ    RPI_GPEDS1,                       0x44
.equ    RPI_GPREN0,                       0x4C
.equ    RPI_GPREN1,                       0x50
.equ    RPI_GPFEN0,                       0x58
.equ    RPI_GPFEN1,                       0x5C
.equ    RPI_GPPUD,                        0x94
.equ    RPI_GPPUDCLK0,                    0x98
.equ    LOAD,                             0x00
.equ    CONTROL,                          0x08
.equ    IRQ_CLEAR,                        0x0C
.equ    RPI_ARMTIMER_CTRL_23BIT,          0x2
.equ    RPI_ARMTIMER_CTRL_PRESCALE_256,   0x8
.equ    RPI_ARMTIMER_CTRL_INT_ENABLE,     0x20
.equ    RPI_ARMTIMER_CTRL_ENABLE,         0x80
.equ    RPI_BASIC_IRQ_PENDING_REG,        0x18
.equ    RPI_BASIC_IRQS,                   0x18
.equ    RPI_BASIC_ARM_TIMER_IRQ,          0x01
.equ    RPI_GPIO_INT_0,                   (1<<17)
.equ    RPI_GPIO_INT_1,                   (1<<18)
.equ    RPI_GPIO_INT_2,                   (1<<19)
.equ    RPI_GPIO_INT_3,                   (1<<20)
.equ    RPI_GPUINTPENDING1,               0x04
.equ    RPI_GPUINTPENDING2,               0x08
// From the ARM ARM (Architecture Reference Manual). Make sure you get the
// ARMv5 documentation which includes the ARMv6 documentation which is the
// correct processor type for the Broadcom BCM2835. The ARMv6-M manuals
// available on the ARM website are for Cortex-M parts only and are very
// different.
//
// See ARM section A2.2 (Processor Modes)
.equ    CPSR_MODE_USER,                   0x10
.equ    CPSR_MODE_FIQ,                    0x11
.equ    CPSR_MODE_IRQ,                    0x12
.equ    CPSR_MODE_SVR,                    0x13
.equ    CPSR_MODE_ABORT,                  0x17
.equ    CPSR_MODE_UNDEFINED,              0x1B
.equ    CPSR_MODE_SYSTEM,                 0x1F
.equ    CPSR_IRQ_INHIBIT,                 0x80
.equ    CPSR_FIQ_INHIBIT,                 0x40
.equ    CPSR_THUMB,                       0x20
.equ    RPI_GPFSEL0,                      0x00
.equ    RPI_GPFSEL1,                      0x04
.equ    RPI_GPFSEL2,                      0x08
.equ    RPI_GPFSEL3,                      0x0c
.equ    RPI_GPFSEL4,                      0x10
.equ    RPI_GPFSEL5,                      0x14
.equ    RPI_GPSET0,                       0x1C
.equ    RPI_GPSET1,                       0x20
.equ    RPI_GPCLR0,                       0x28
.equ    RPI_GPCLR1,                       0x2C
.equ    RPI_GPLEV0,                       0x34
.equ    RPI_GPLEV1,                       0x38
// Setup Frame Buffer constants
.equ SCREEN_X,       640
.equ SCREEN_Y,       480
.equ BITS_PER_PIXEL, 32
// UART Constants
.equ UART0_DR,						0x00
.equ UART0_RSRECR,					0x04
.equ UART0_FR,						0x18
.equ UART0_IBRD,						0x24
.equ UART0_FBRD,						0x28
.equ UART0_LCRH,						0x2c
.equ UART0_CR,						0x30
.equ UART0_IFLS,						0x34
.equ UART0_IMSC,						0x38
.equ UART0_RIS,						0x3c
.equ UART0_MIS,						0x40
.equ UART0_ICR,						0x44
.equ UART0_DMACR,					0x48
.equ UART0_CLOCK,					300000000

.equ UART0_LCRH_BRK,					0x00
.equ UART0_LCRH_PEN,					0x01
.equ UART0_LCRH_EPS,					0x02
.equ UART0_LCRH_STP2,				0x03
.equ UART0_LCRH_FEN,					0x04
.equ UART0_LCRH_WLEN,				0x05

.equ UART0_CR_UARTEN,				0x00
.equ UART0_CR_TXE,					0x08
.equ UART0_CR_RXE,					0x09

.equ UART0_FR_RXFE,					0x04
.equ UART0_FR_TXFF,					0x05

