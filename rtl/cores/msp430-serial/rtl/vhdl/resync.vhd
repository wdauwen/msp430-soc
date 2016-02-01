----------------------------------------------------------------------------------
-- This work is licensed under the Creative Commons 
-- Attribution-NonCommercial-ShareAlike 3.0 Unported License. To view a copy of 
-- this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send 
-- a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, 
-- California, 94105, USA.
--
-- Created by Sven Gulikers
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity resync is
	generic ( LEVEL_IN_RESET : STD_LOGIC := '0');
	port ( CLK           : in  STD_LOGIC;
		   SIG_IN        : in  STD_LOGIC;
		   SIG_OUT       : out STD_LOGIC;
		   nRESET        : in  STD_LOGIC );
end resync;

architecture Behavioral of resync is
	signal sync1, sync2 : STD_LOGIC;
begin

	sync : process (nRESET, CLK)
	begin
		if nRESET = '0' then 
			sync1 <= LEVEL_IN_RESET;
			sync2 <= LEVEL_IN_RESET;
		elsif CLK'event and CLK = '1' then
			sync2 <= sync1;
			sync1 <= SIG_IN;
		end if;
	end process;

	SIG_OUT <= sync2; 

end Behavioral;
