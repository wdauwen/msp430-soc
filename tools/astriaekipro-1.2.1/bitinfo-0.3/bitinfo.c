/* bitinfo.c
 *
 * Main function to parse Xilinx bit file header, version 0.2.
 *
 * Copyright 2001, 2002 by David Sullins
 *
 * This file is part of Bitinfo.
 * 
 * Bitinfo is free software; you can redistribute it and/or modify it under the
 * terms of the GNU General Public License as published by the Free Software
 * Foundation, version 2 of the License.
 * 
 * Bitinfo is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * Bitinfo; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place, Suite 330, Boston, MA 02111-1307 USA
 * 
 * You may contact the author at djs@naspa.net.
 */


#include <stdio.h>
#include <stdlib.h>
#include "bitfile.h"

/* read a bit file from stdin */
int main(void)
{
	int t;
	struct bithead bh;
	
	initbh(&bh);
	
	/* read header */
	t = readhead(&bh, stdin);
	if (t)
	{
		printf("Invalid bit file header.\n");
		exit(1);
	}
	
	/* output header info */
	printf("\n");
	printf("Bit file created on %s at %s.\n", bh.date, bh.time);
	printf("Created from file %s for Xilinx part %s.\n", bh.filename, 
	       bh.part);
	printf("Bitstream length is %d bytes.\n", bh.length);
	printf("\n");
	
	freebh(&bh);
	
	return 0;
}
