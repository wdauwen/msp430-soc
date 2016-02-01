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
 
entity test_baudrate is
end test_baudrate;
 
architecture Behavioral of test_baudrate is 
     -- Component Declaration for the Unit Under Test (UUT)
	component baudgen is
		port ( CLK         : in  STD_LOGIC;
			   nRESET      : in  STD_LOGIC;
			   BAUD_CLK    : out STD_LOGIC;
			   BAUD_CLK_X8 : out STD_LOGIC;
	           DIV         : in  STD_LOGIC_VECTOR (3 downto 0) );
	end component;

   --Inputs
   signal CLK_50MHZ : STD_LOGIC := '0';

 	--Outputs
   signal BAUD_CLK, BAUD_CLK_X8 : STD_LOGIC;

   -- Clock period definitions
   constant CLK_period : time := 20 ns;
   constant BAUD_period : time := 8680 ns;	-- 115200
begin

	-- Instantiate the Unit Under Test (UUT)
	uut: baudgen 
		port map (CLK => CLK_50MHZ, nRESET => '1',
				  BAUD_CLK => BAUD_CLK, BAUD_CLK_X8 => BAUD_CLK_X8,
				  DIV => "0000");

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
	begin		
		-- hold reset state for 100 ns.
		wait for 100 ns;	
	
		-- just check the timing, baudrate should be at 115200
		-- oversampling should be 8 times faster	
		wait;
	end process;

end Behavioral;
