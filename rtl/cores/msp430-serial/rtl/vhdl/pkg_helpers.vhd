library IEEE;
use IEEE.STD_LOGIC_1164.all;

package pkg_helpers is

component flancter is
	port ( SET_CE        : in  STD_LOGIC;
		   SET_CLK       : in  STD_LOGIC;
		   CLR_CE        : in  STD_LOGIC;
		   CLR_CLK       : in  STD_LOGIC;
		   nRESET        : in  STD_LOGIC;
		   FLAG          : out STD_LOGIC );
end component;

component resync is
	generic ( LEVEL_IN_RESET : STD_LOGIC := '0');
	port ( CLK           : in  STD_LOGIC;
		   SIG_IN        : in  STD_LOGIC;
		   SIG_OUT       : out STD_LOGIC;
		   nRESET        : in  STD_LOGIC );
end component;

component pulse is
	port ( CLK      : in  STD_LOGIC;
		   nRESET   : in  STD_LOGIC;
		   SIG      : in  STD_LOGIC;
		   P_RISE   : out STD_LOGIC;
		   P_FALL   : out STD_LOGIC );
end component;

end pkg_helpers;
