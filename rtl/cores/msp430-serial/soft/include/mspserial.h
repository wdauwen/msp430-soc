#ifndef _MSPSERIAL_H
#define _MSPSERIAL_H

int serial_putchar(int base, int c);
int serial_getchar(int base);
int serial_getchar_check(int base);

int serial_get_fifolevel(int base);

// All registers are system bus wide

#ifndef SYSBUS_BIT
#define SYSBUS_BIT	16
#endif

#define _BYTES		(SYSBUS_BIT / 8)

#define SER_STATUS		(0 * _BYTES)
#define SER_DATA		(1 * _BYTES)
#define SER_LEVEL		(2 * _BYTES)
#define SER_BAUD		(3 * _BYTES)

// SER_STATUS bits
#define STAT_TX_BUSY	(1<<0)
#define STAT_RX_BUSY	(1<<1)
#define STAT_RX_DONE	(1<<2)
#define STAT_EMPTY		(1<<3)
#define STAT_FULL		(1<<4)
#define STAT_FIFO_EN	(1<<7)
#define STAT_LOOPBACK	(1<<8)

// based on 4MHz reference clock
#define BAUD_115200		2
#define BAUD_38400		6
#define BAUD_19200		12
#define BAUD_9600		24

#endif
