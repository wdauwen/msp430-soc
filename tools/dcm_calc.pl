#!/usr/bin/perl

#CLKDV_DIVIDE => 2.5,                   -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
#                                       -- 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
#CLKFX_DIVIDE => 1,                     -- Can be any interger from 1 to 32
#CLKFX_MULTIPLY => 4,                   -- Can be any integer from 1 to 32

$numArgs = $#ARGV + 1;
if ($numArgs != 2) {
    print "Wrong number of arguments!\n";
    print "dcm_calc.pl [reference clock] [target clock]\n";
    exit;
}

$CLK_REF = $ARGV[0];
$CLK_TARGET = $ARGV[1];

@CLKDV_DIVIDE = (1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0,16.0);

# DV output
print "Divider only:\n";
foreach $div (@CLKDV_DIVIDE) {
	$freq = $CLK_REF / $div;
	$err = 100 - ($CLK_TARGET / $freq * 100);

	if (abs($err) < 5) {
		print "D=$div err=$err% -> $freq\n";
	}
}

# FX output
print "\nFX output:\n";
for ($div = 1; $div <= 32; $div++) {
	for ($multi = 2; $multi <= 32; $multi++) {
		$freq = $CLK_REF / $div * $multi;
		$err = 100 - ($CLK_TARGET / $freq * 100);

		if (abs($err) < 5) {
			printf "D=$div M=$multi err=$err% -> $freq\n";
		}
	}
}

