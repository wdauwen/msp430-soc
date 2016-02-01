#include <stdio.h>

#include "hardware.h"
#include "hwio.h"
#include "platform.h"

#include "mspgpio.h"

#define BTN_NORTH		(1<<6)
#define BTN_SOUTH		(1<<5)
#define BTN_WEST		(1<<4)

#define SW3				(1<<3)
#define SW2				(1<<2)
#define SW1				(1<<1)
#define SW0				(1<<0)

/* a software delay loop */
void delay(unsigned int c, unsigned int d) {
  int i, j;
  for (i = 0; i<c; i++) {
    for (j = 0; j<d; j++) {
      nop();
      nop();
    }
  }
}

/**
This one is executed onece a second. it counts seconds, minues, hours - hey
it shoule be a clock ;-)
it does not count days, but i think you'll get the idea.
*/
volatile int irq_counter, flag;

wakeup interrupt (WDT_VECTOR) INT_Watchdog(void) {

  irq_counter++;
  if (irq_counter == 300) {
    irq_counter = 0;
    flag = 1;
  }
}

int main(void) {
    int i;
    int o = 0;

    printf("Hello world!\r\n");

    irq_counter = 0;
    flag        = 0;

    WDTCTL = WDTPW | WDTHOLD;          // Disable watchdog timer
    // Configure watchdog interrupt
    WDTCTL = WDTPW | WDTTMSEL | WDTCNTCL;// | WDTIS1  | WDTIS0 ;

    IE1 |= 0x01;
    eint();                            //enable interrupts

    // enable the outputs
    iowrite16(0xFF, BASE_GPIO0+GPIO_DIR);
	iowrite16(0xF, BASE_VGA0);

    // Play with the lights
    // Main loop, never ends...
    while (1) {
		if (flag) {
			flag = 0;
		    printf("OPENMSP430 running...\r\n");
    	}
		if (ioread16(BASE_GPIO0+GPIO_IN) & BTN_SOUTH) {
			for (i=0; i<8; i++, o++) {
				iowrite16((1<<i) | (0x80>>(o&7)), BASE_GPIO0+GPIO_OUT);
				iowrite16(i, BASE_VGA0);

				delay(0x0007, 0xffff);
			}
		} else {
			iowrite16(0xAA, BASE_GPIO0+GPIO_OUT);
		}
    }
}

