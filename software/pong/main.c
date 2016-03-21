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
	int i, dirv =1;
	int state = 0;
	int dirh =1;
	int dirp=4;
    WDTCTL = WDTPW | WDTHOLD;          // Disable watchdog timer


    // enable the outputs
    iowrite16(240, BASE_VGA0 + baly);
    iowrite16(240, BASE_VGA0 + balx);
    iowrite16(240, BASE_VGA0 + padx);


    while (1) {
    //vertical ball movement
    	i = ioread16(BASE_VGA0 + baly);
    	i = i + dirv;
    	if (i > 480 -12)
    		{dirv = dirv * -1;
    		}
    	if (i < 0)
    	{dirv = dirv * -1;
    	}

    iowrite16(i, BASE_VGA0 + baly);
    delay (1,0x100f);

    // horizontal ball movement
    i = ioread16(BASE_VGA0 + balx);
        	i = i + dirh;
        	if (i > 640 -12)
        		{dirh = dirh * -1;
        		}
        	if (i < 0)
        	{dirh= dirh * -1;
        	}

        iowrite16(i, BASE_VGA0 + balx);
        delay (1,0x100f);

    //Paddle movement
       i = ioread16(BASE_VGA0 + padx);
           	i = i + dirp;
          	if (i > 480 -12)
          		{dirp = dirp * -1;
          		}
          	if (i < 0)
          	{dirp = dirp * -1;
          	}

          iowrite16(i, BASE_VGA0 + padx);
          delay (1,0x100f);

<<<<<<< HEAD
    //	if (ioread16(BASE_GPIO0+GPIO_IN)& BTN_NORTH) {
    //		if (state == 0)
   	//   {
    //		dirp = dirp * -1;
    //		state = 1;
   	//	}
    //	} else {
    //		state = 0;
    //	}
    //		}
          if (ioread16(BASE_GPIO0+GPIO_IN)& BTN_NORTH) {
        	  dirp = 4;
          }
          else if (ioread16(BASE_GPIO0+GPIO_IN)& BTN_SOUTH) {
          	  dirp = -4;
            }
          else {
        	  dirp = 0;
          }

    }
}
=======
    	if (ioread16(BASE_GPIO0+GPIO_IN)& BTN_SOUTH) {
    		if (state == 0)
   	   {
    		dirp = dirp * -1;
    		state = 1;
   		}
    	} else {
    		state = 0;
    	}
    		}
>>>>>>> 43fe933dae79776ed45834c25c94904089b05bb2





