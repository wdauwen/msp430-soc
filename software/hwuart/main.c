#include <stdio.h>

#include "hardware.h"
#include "hwio.h"
#include "platform.h"

#include "mspgpio.h"
#include "mspserial.h"

int main(void) {
	int i;

    WDTCTL = WDTPW | WDTHOLD;          // Disable watchdog timer

	// enable fifo
	iowrite16(STAT_FIFO_EN, BASE_UART0+SER_STATUS);
	iowrite16(BAUD_115200, BASE_UART0+SER_BAUD);

	iowrite16(STAT_FIFO_EN, BASE_UART1+SER_STATUS);
	iowrite16(BAUD_115200, BASE_UART1+SER_BAUD);

	printf("\r\n====== UART loopback example ======\r\n");

	iowrite16(0xFF, BASE_GPIO0+GPIO_DIR);
	iowrite16(0x80, BASE_GPIO0+GPIO_OUT);

    while(1) { 
		/* echo loop */
		if ( serial_getchar_check(BASE_UART0) ) {
			i = serial_getchar(BASE_UART0);
			serial_putchar(BASE_UART0, i);

			iowrite16( (ioread16(BASE_GPIO0+GPIO_OUT) ^ 0x1), BASE_GPIO0+GPIO_OUT);
		}

		if ( serial_getchar_check(BASE_UART1) ) {
			i = serial_getchar(BASE_UART1);
			serial_putchar(BASE_UART1, i);

			iowrite16( (ioread16(BASE_GPIO0+GPIO_OUT) ^ 0x2), BASE_GPIO0+GPIO_OUT);
		}
	}
}

