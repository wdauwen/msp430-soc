#!/usr/bin/perl

$file = "/mnt/workspace/gt/msp430-soc/software/leds/gcc/leds.bin";
$byte = 0;

$file = $ARGV[0];
$byte = $ARGV[1];

printf "library IEEE;\n";
printf "use IEEE.STD_LOGIC_1164.ALL;\n";
printf "use IEEE.STD_LOGIC_ARITH.ALL;\n";
printf "use IEEE.STD_LOGIC_UNSIGNED.ALL;\n";
printf "\n";
if ($byte == 0) {
	printf "entity rom_8x2k_lo is\n";
} else {
	printf "entity rom_8x2k_hi is\n";
}
printf "	generic (\n";
printf "		MEM_AWIDTH : integer := 11\n";
printf "	);\n";
printf "	port (\n";
printf "		addr : in  STD_LOGIC_VECTOR(MEM_AWIDTH-1 downto 0);\n";
printf "		dout : out STD_LOGIC_VECTOR(7 downto 0);\n";
printf "		din  : in  STD_LOGIC_VECTOR(7 downto 0);\n";
printf "		en   : in  STD_LOGIC;	-- low active\n";
printf "		clk  : in  STD_LOGIC;\n";
printf "		we   : in  STD_LOGIC	-- low active\n";
printf "	);	\n";
if ($byte == 0) {
	printf "end rom_8x2k_lo;\n";
} else {
	printf "end rom_8x2k_hi;\n";
}
printf "\n";
if ($byte == 0) {
	printf "architecture Behavioral of rom_8x2k_lo is \n";
} else {
	printf "architecture Behavioral of rom_8x2k_hi is \n";
}
printf "	type mem is array (2**MEM_AWIDTH-1 downto 0) of STD_LOGIC_VECTOR(din'range);\n";
printf "	signal memory : mem := (\n		";

open(FILE, $file);

binmode(FILE);

$start = 0;
until ( eof(FILE) )
{
		if ($start > 0) {
			printf(", ");
			if ($start % 16 == 0) {
				printf("\n		");
			}
		}
		$start = $start + 1;

        read(FILE, $record, 2) == 2 
                or die "short read\n";

        $i = 0;
        foreach (split(//, $record)) {
			if ($byte == $i) {
        		printf("x\"%02x\" ", ord($_));
			}
			$i = $i + 1;
		}
}
printf("\n");

printf "	);\n";
printf "\n";
printf "	signal addr_reg : STD_LOGIC_VECTOR(MEM_AWIDTH-1 downto 0);\n";
printf "begin\n";
printf "\n";
printf "	process (clk)\n";
printf "	begin\n";
printf "		if (clk'event and clk = '1') then\n";
printf "			if (en = '0') then\n";
printf "				addr_reg <= addr;\n";
printf "			end if;\n";
printf "		end if;\n";
printf "	end process;\n";
printf "\n";
printf "	dout <= memory(conv_integer(addr_reg));\n";
printf "\n";
printf "end Behavioral;\n";

