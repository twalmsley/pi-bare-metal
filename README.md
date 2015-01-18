This repository was originally cloned from:

    Raspberry-Pi Bare Metal Tutorial
    ================================
    code is at http://www.valvers.com/embedded-linux/raspberry-pi

Now there is virtually none of the original code in here, just a few snippets needed to initialise the stacks and interrupts. Many thanks to the original developer for bootstrapping me into bare metal on the Pi.

. ARM-library - common code for video, console io, gertboard peripherals, interrupt handling etc.

. Test001 - Use the Gertboard LEDs to display a pattern.

. Test002 - Similar to the above example, but using assembler. All later examples use Assembler rather than C/C++.

. Test003 - Display a binary counter on the Gertboard LEDs. Count up or down depending on the button pressed.

. Test004 - Use interrupts for the Gertboard buttons.Interrupt handler now needs to check which interrupt occurred so it can handle the right one.

. Test005 - Better handling of buttons and LEDs. Nothing to do with gertboard relays despite the project name.

. Test006 - Game of Life in assembler for 640x480 screen. Uses code from the ARM-library project.

. Test007 - Some simple graphics code added to the library and exercised here.

. Test008 - A simple text terminal skeleton - gives a prompt and can display text on the HDMI and/or UART. Good for adding debug statements.

. Test009 - Use SPI to set up the Gertboard DAC and ADC then constantly read values from the ADC.
