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
 
entity test_receiver is
end test_receiver;
 
architecture Behavioral of test_receiver is 
    -- Component Declaration for the Unit Under Test (UUT)
	component baudgen is
		port ( CLK         : in  STD_LOGIC;
			   nRESET      : in  STD_LOGIC;
			   BAUD_CLK    : out STD_LOGIC;
			   BAUD_CLK_X8 : out STD_LOGIC;
	           DIV         : in  STD_LOGIC_VECTOR (4 downto 0) );
	end component;

	component rx is
	    port ( CLK_SYS     : in  STD_LOGIC;
	           CLK_BAUD_X8 : in  STD_LOGIC;
	           nRESET      : in  STD_LOGIC;
	           RXD         : in  STD_LOGIC;
	           rx_busy     : out STD_LOGIC;
	           rx_done     : out STD_LOGIC;
	           rx_char     : out STD_LOGIC_VECTOR (7 downto 0) );
	end component;

	--Inputs
	signal CLK_I, CLK_BAUDGEN : STD_LOGIC := '0';
	signal RXD : STD_LOGIC := '1';
	signal nRESET : STD_LOGIC := '1';
	signal baudrate, baudrate_x8 : STD_LOGIC := '0';

	--Outputs
	signal TXD : STD_LOGIC;
	signal rx_busy, rx_done : STD_LOGIC;
	signal rx_char : STD_LOGIC_VECTOR (7 downto 0) := x"00"; 

	-- Clock period definitions
    constant CLK_period_20 : time := 50 ns;    -- 20MHz
    constant CLK_period_4  : time := 271.3 ns; -- 3...MHz
	constant BAUD_period : time := 8680 ns;	-- 115200
begin

	clockgen : baudgen
		port map ( CLK => CLK_BAUDGEN, nRESET => nRESET, DIV => "00010",
				   BAUD_CLK => baudrate, BAUD_CLK_X8 => baudrate_x8);

	-- Instantiate the Unit Under Test (UUT)
	uut: rx 
		port map (CLK_SYS => CLK_I, CLK_BAUD_X8 => baudrate_x8,
				  nRESET => nRESET, RXD => RXD,
				  rx_busy => rx_busy, rx_done => rx_done, rx_char => rx_char);

    CLK_process_20 : process
    begin
        CLK_I <= '0';
        wait for CLK_period_20/2;
        CLK_I <= '1';
        wait for CLK_period_20/2;
    end process;

    CLK_process_4 : process
    begin
        CLK_BAUDGEN <= '0';
        wait for CLK_period_4/2;
        CLK_BAUDGEN <= '1';
        wait for CLK_period_4/2;
    end process;
	
	-- Stimulus process
	stim_proc: process
		variable I : integer range 0 to 20;
	begin		
		-- reset
		wait for 10 us;	
		nRESET <= '0';
		wait for 2 us;
		nRESET <= '1';	
	
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
	
			wait for BAUD_period/10*3;
	
			I := I + 1;
		end loop;
	
		-- normally the system should start sending out something
		wait;
	end process;

end Behavioral;
