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

entity flancter is
	port ( SET_CE        : in  STD_LOGIC;
		   SET_CLK       : in  STD_LOGIC;
		   CLR_CE        : in  STD_LOGIC;
		   CLR_CLK       : in  STD_LOGIC;
		   nRESET        : in  STD_LOGIC;
		   FLAG          : out STD_LOGIC );
end flancter;

architecture Behavioral of flancter is
	signal ff1_o, ff2_o : STD_LOGIC := '0';
begin

	ff1 : process (nRESET, SET_CE, SET_CLK)
	begin
		if nRESET = '0' then
			ff1_o <= '0';	
		elsif SET_CLK'event and SET_CLK = '1' then
			if SET_CE = '1' then
				ff1_o <= not ff2_o;
			end if;
		end if;
	end process;

	ff2 : process (nRESET, CLR_CE, CLR_CLK)
	begin
		if nRESET = '0' then
			ff2_o <= '0';	
		elsif CLR_CLK'event and CLR_CLK = '1' then
			if CLR_CE = '1' then
				ff2_o <= ff1_o;
			end if;
		end if;
	end process;

	FLAG <= ff1_o xor ff2_o;

end Behavioral;
