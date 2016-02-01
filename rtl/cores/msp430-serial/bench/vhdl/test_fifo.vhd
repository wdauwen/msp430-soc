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
 
entity test_fifo is
end test_fifo;
 
architecture Behavioral of test_fifo is 
     -- Component Declaration for the Unit Under Test (UUT)
	component fifo_8x16 is
		port ( CLK   : in  STD_LOGIC;
			   di    : in  STD_LOGIC_VECTOR (7 downto 0);
			   do    : out STD_LOGIC_VECTOR (7 downto 0);
			   wr_en : in  STD_LOGIC;
	           rd_en : in  STD_LOGIC;
			   empty : out STD_LOGIC;
			   full  : out STD_LOGIC );
	end component;

   --Inputs
   signal CLK   : STD_LOGIC := '0';
   signal di    : STD_LOGIC_VECTOR (7 downto 0) := "00000000";
   signal wr_en : STD_LOGIC := '0';
   signal rd_en : STD_LOGIC := '0';
   signal empty : STD_LOGIC := '0';
   signal full  : STD_LOGIC := '0';

 	--Outputs
   signal do    : STD_LOGIC_VECTOR (7 downto 0) := "00000000";

   -- Clock period definitions
   constant CLK_period : time := 20 ns;
begin

	-- Instantiate the Unit Under Test (UUT)
	uut: fifo_8x16
		port map (CLK => CLK, di => di, do => do,
				  wr_en => wr_en, rd_en => rd_en, empty => empty, full => full);

	-- Clock process definitions
	CLK_process : process
	begin
	 	CLK <= '0';
	 	wait for CLK_period/2;
	 	CLK <= '1';
		wait for CLK_period/2;
	end process;
 
  	 -- Stimulus process
   	stim_proc: process
	begin		
		-- hold reset state for 100 ns.
		wait for 100 ns;	
		
		wait for CLK_period*10;
		
		-- insert stimulus here 
		di <= x"50";
		wait for CLK_period;	wr_en <= '1';
		wait for CLK_period;	wr_en <= '0';
		assert (empty = '0') report "empty flasg not functional" severity failure;

		di <= x"51";
		wait for CLK_period;	wr_en <= '1';
		wait for CLK_period;	wr_en <= '0';

		wait for CLK_period;	rd_en <= '1';
		wait for CLK_period;	rd_en <= '0';

		wait for CLK_period;	rd_en <= '1';
		wait for CLK_period;	rd_en <= '0';

		assert (empty = '1') report "empty flasg not functional" severity failure;
		
		wait;
   end process;

end Behavioral;
