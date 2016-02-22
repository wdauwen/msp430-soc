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
/* define offset registers */
#define baly			(0x0)
#define balx			(0x2)
#define padx			(0x4)

#define X_max 			640
#define X_min			480


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

int main(void) {
	int i, dir =1;
	int state = 0;
    WDTCTL = WDTPW | WDTHOLD;          // Disable watchdog timer


    // enable the outputs
    iowrite16(0x240, BASE_VGA0 + baly);
    iowrite16(0x240, BASE_VGA0 + balx);
    iowrite16(0x240, BASE_VGA0 + padx);


    while (1) {
    	i = ioread16(BASE_VGA0 + baly);
    	i = i + dir;
    	if (i > 480)
    		{i =0;
    	}
    	iowrite16(i, BASE_VGA0 + baly);
    	delay (1,0x2fff);
    	if (ioread16(BASE_GPIO+GPIO_IN)& BTN_SOUTH) {
    		if (state == 0) {
    			dir = dir * -1;
    			state = 1;
    		}
    	} else {
    		state = 0;
    	}
    		}

    	}

    }
}

