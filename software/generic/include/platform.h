#ifndef _PLATFORM_H
#define _PLATFORM_H

/* processor specific things */
#define BASE_WDG		(0x120)		/* (1 register) */
#define BASE_CLOCK		(0x057)		/* (2 register) */
#define BASE_INT		(0x000)		/* (4 register) */

/* extended peripherals
 *  - range 0x10 - 0x50
 *  - every peripheral can have 8 16bit registers
 */
#define BASE_GPIO0		(0x08 << 1) /* 0x010 */
#define BASE_UART0		(0x10 << 1) /* 0x020 */
#define BASE_VGA0		(0x18 << 1) /* 0x030 */
#define BASE_DAC0		(0x20 << 1) /* 0x040 */
/* memory range 0x50 till 0x60 is reserved, do not use */
#define BASE_LCD0		(0x30 << 1) /* 0x060 till 0x80 */
#define BASE_UART1		(0x40 << 1) /* 0x080 */

/* defines for standard library */
#define BASE_STDIOUART	BASE_UART0

#endif
