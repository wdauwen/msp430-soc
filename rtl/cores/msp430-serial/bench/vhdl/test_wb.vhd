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
 
entity test_wb is
end test_wb;
 
architecture Behavioral of test_wb is 
    -- Component Declaration for the Unit Under Test (UUT)
	component serial_msp is
		port ( 
	           -- UART signals
	           CLK_BAUDGEN : in  STD_LOGIC;
    		   TXD         : out STD_LOGIC;
    		   RXD         : in  STD_LOGIC;
    		   -- WISHBONE BUS
    		   RST_I       : in  STD_LOGIC;
    		   CLK_I       : in  STD_LOGIC;                    
               ADR_I       : in  STD_LOGIC_VECTOR( 1 downto 0);
    		   DAT_I       : in  STD_LOGIC_VECTOR(15 downto 0);
               DAT_O       : out STD_LOGIC_VECTOR(15 downto 0);
    		   WE_I        : in  STD_LOGIC;
               SEL_I       : in  STD_LOGIC_VECTOR( 1 downto 0);
               STB_I       : in  STD_LOGIC 
		);
	end component;

	-- Local signals
	signal CLK_BAUDGEN : STD_LOGIC := '0';
	signal TXD		   : STD_LOGIC;
	signal RXD         : STD_LOGIC := '1';
	signal RST_I       : STD_LOGIC := '0';
	signal CLK_I       : STD_LOGIC;
	signal ADR_I       : STD_LOGIC_VECTOR( 1 downto 0) := "00";
	signal DAT_I       : STD_LOGIC_VECTOR(15 downto 0) := "0000000000000000";
	signal DAT_O       : STD_LOGIC_VECTOR(15 downto 0) := "0000000000000000";
	signal WE_I        : STD_LOGIC := '0';
	signal SEL_I       : STD_LOGIC_VECTOR( 1 downto 0) := "00";
	signal STB_I       : STD_LOGIC := '0';

   -- Clock period definitions
    constant CLK_period_20 : time := 50 ns;    -- 20MHz
    constant CLK_period_4  : time := 271.3 ns; -- 3...MHz
	constant BAUD_period : time := 8680 ns;	-- 115200
begin

	-- Instantiate the Unit Under Test (UUT)
	uut: serial_msp port map (
		CLK_BAUDGEN => CLK_BAUDGEN, TXD => TXD, RXD => RXD,	
        RST_I => RST_I, CLK_I => CLK_I, ADR_I => ADR_I,
        DAT_I => DAT_I, DAT_O => DAT_O, WE_I => WE_I,
        SEL_I => SEL_I, STB_I => STB_I
    );

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
		RXD <= '1';	
		-- hold reset state for 100 ns.
		wait for 100 ns;	
	
		RST_I <= '1';
        wait for CLK_period_20*2;
        RST_I <= '0';
        wait for CLK_period_20;

		-- send out a character
		DAT_I <= x"0041";
        ADR_I <= "01";
        WE_I <= '1'; STB_I <= '1'; SEL_I <= "11";
        wait for CLK_period_20;
        WE_I <= '0'; STB_I <= '0'; SEL_I <= "00";

        wait for CLK_period_20;

		-- test seemed to fail when stressing system,
		L1: loop
			exit L1 when I = 3;

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

			-- clear character
			DAT_I <= x"0041";
   		    WE_I <= '0'; STB_I <= '1'; SEL_I <= "11";
       		wait for CLK_period_20;
        	WE_I <= '0'; STB_I <= '0'; SEL_I <= "00";
	
			I := I + 1;
		end loop;

		wait;
	end process;

end Behavioral;
