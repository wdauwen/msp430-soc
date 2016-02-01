#ifndef _HWIO_H
#define _HWIO_H

// register access functions
#define iowrite16(v, a)		(*((volatile unsigned int *)(a)) = v)
#define ioread16(a)			(*((volatile unsigned int *)(a)))

#endif
