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
--USE ieee.numeric_std.ALL;
 
entity test_loopback is
end test_loopback;
 
architecture Behavioral of test_loopback is 
     -- Component Declaration for the Unit Under Test (UUT)
	component serial is
		port ( CLK_50MHZ  : in  STD_LOGIC;
			   TXD        : out STD_LOGIC;
			   RXD        : in  STD_LOGIC );
	end component;

   --Inputs
   signal CLK_50MHZ : STD_LOGIC := '0';
   signal RXD : STD_LOGIC := '1';

 	--Outputs
   signal TXD : STD_LOGIC;

   -- Clock period definitions
   constant CLK_period : time := 20 ns;
   constant BAUD_period : time := 8680 ns;	-- 115200
begin

	-- Instantiate the Unit Under Test (UUT)
	uut: serial 
		port map (CLK_50MHZ => CLK_50MHZ, TXD => TXD, RXD => RXD);

	-- Clock process definitions
	CLK_process : process
	begin
	 	CLK_50MHZ <= '0';
	 	wait for CLK_period/2;
	 	CLK_50MHZ <= '1';
	 	wait for CLK_period/2;
	end process;
	
	-- Stimulus process
	stim_proc: process
		variable I : integer range 0 to 20;
	begin		
		-- reset
		wait for 10 us;	

		-- test seemed to fail when stressing system,
		L1: loop
			exit L1 when I = 20;

			-- insert stimulus here 
			-- receive a character, LSB first
			-- 01001010 -> 0101 0010 -> 0x52 -> char 'R'
			RXD <= '0';	wait for BAUD_period;
	
			RXD <= '0';	wait for BAUD_period;
			RXD <= '1';	wait for BAUD_period;
			RXD <= '0';	wait for BAUD_period;
			RXD <= '0';	wait for BAUD_period;
			RXD <= '1';	wait for BAUD_period;
			RXD <= '0';	wait for BAUD_period;
			RXD <= '1';	wait for BAUD_period;
			RXD <= '0';	wait for BAUD_period;
	
			RXD <= '1';	wait for BAUD_period;
	
			I := I + 1;
		end loop;
	
		-- normally the system should start sending out something
		wait;
	end process;

end Behavioral;
