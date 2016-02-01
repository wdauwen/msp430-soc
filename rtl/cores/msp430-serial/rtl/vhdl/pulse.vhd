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

entity pulse is
	port ( CLK      : in  STD_LOGIC;
		   nRESET   : in  STD_LOGIC;
		   SIG      : in  STD_LOGIC;
		   P_RISE   : out STD_LOGIC;
		   P_FALL   : out STD_LOGIC );
end pulse;

architecture Behavioral of pulse is
	signal sig_b : STD_LOGIC := '0';
begin
	
	pulse : process (nRESET, CLK)
	begin
		if nRESET = '0' then
			sig_b <= '0';
		elsif (CLK'event and CLK = '1') then
			sig_b <= SIG;
		end if;
	end process;

	P_FALL <= not SIG and     sig_b;
	P_RISE <=     SIG and not sig_b;

end Behavioral;
