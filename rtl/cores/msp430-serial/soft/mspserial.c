
#include <stdio.h>
#include "mspserial.h"
#include "platform.h"

int serial_putchar(int base, int c)
{
	volatile int *stat_reg, *data_reg;

	stat_reg = (volatile int *)(base + SER_STATUS);
	data_reg = (volatile int *)(base + SER_DATA);

	// wait until buffer is free
	while ( *stat_reg & STAT_TX_BUSY );
	*data_reg = c;

	return 0;
}

int serial_getchar(int base)
{
	volatile int *stat_reg, *data_reg;
	volatile int stat;

	stat_reg = (volatile int *)(base + SER_STATUS);
	data_reg = (volatile int *)(base + SER_DATA);

	while (1) {
		stat = *stat_reg;

		if ( stat & STAT_RX_DONE )
			break;

		if ( (stat & STAT_FIFO_EN) && (stat & STAT_EMPTY) == 0 )
			break;
	}

	return *data_reg;
}

int serial_getchar_check(int base)
{
	volatile int *stat_reg;
	volatile int stat;

	stat_reg = (volatile int *)(base + SER_STATUS);
	stat = *stat_reg;

	if ( stat & STAT_RX_DONE )
		return 1;

	if ( (stat & STAT_FIFO_EN) && (stat & STAT_EMPTY) == 0 )
		return 1;

	if ( serial_get_fifolevel(base) )
		return 1;

	return 0;
}

int putchar(int c)
{
	return serial_putchar(BASE_STDIOUART, c);
}

int serial_get_fifolevel(int base)
{
	volatile int *level_reg;

	level_reg = (volatile int *)(base + SER_LEVEL);

	return *level_reg;
}

