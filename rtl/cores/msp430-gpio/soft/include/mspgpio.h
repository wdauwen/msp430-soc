#ifndef _MSPGPIO_H
#define _MSPGPIO_H

// All registers are system bus wide
// However, the datawidth of the bus is only 8 bits, room for improvement

#define GPIO_IN		0x00
#define GPIO_OUT	0x02
#define GPIO_DIR	0x04

#endif
