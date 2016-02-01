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
 
entity test_transmit is
end test_transmit;
 
architecture Behavioral of test_transmit is 
    -- Component Declaration for the Unit Under Test (UUT)
	component baudgen is
		port ( CLK         : in  STD_LOGIC;
			   nRESET      : in  STD_LOGIC;
			   BAUD_CLK    : out STD_LOGIC;
			   BAUD_CLK_X8 : out STD_LOGIC;
	           DIV         : in  STD_LOGIC_VECTOR (3 downto 0) );
	end component;

	component tx is
		port ( CLK_SYS  : in  STD_LOGIC;
			   CLK_BAUD : in  STD_LOGIC;
		   	   nRESET   : in  STD_LOGIC;
			   TXD      : out STD_LOGIC;
			   tx_start : in  STD_LOGiC;
			   tx_busy  : out STD_LOGIC;
	           tx_char  : in  STD_LOGIC_VECTOR (7 downto 0) );
	end component;

	--Inputs
	signal CLK_50MHZ : STD_LOGIC := '0';
	signal nRESET : STD_LOGIC := '1';
	signal baudrate, baudrate_x8 : STD_LOGIC := '0';

	--Outputs
	signal TXD : STD_LOGIC;
	signal tx_start, tx_busy : STD_LOGIC := '0';

	-- Clock period definitions
	constant CLK_period : time := 20 ns;
	constant BAUD_period : time := 8680 ns;	-- 115200
begin

	clockgen : baudgen
		port map ( CLK => CLK_50MHZ, nRESET => nRESET, DIV => "0000",
				   BAUD_CLK => baudrate, BAUD_CLK_X8 => baudrate_x8);

	-- Instantiate the Unit Under Test (UUT)
	uut : tx
		port map ( CLK_SYS => CLK_50MHZ, CLK_BAUD => baudrate, 
				   nRESET => nRESET, TXD => TXD,
				   tx_start => tx_start, tx_busy => tx_busy, tx_char => x"48");

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
		-- reset
		wait for 10 us;	
		nRESET <= '0';
		wait for 2 us;
		nRESET <= '1';	
	
		wait for 10 us;	

		-- send a character	
		tx_start <= '1';
		wait for CLK_period;
		tx_start <= '0';
	
		wait;
	end process;

end Behavioral;
