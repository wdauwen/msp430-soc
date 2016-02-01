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
 
entity test_sys is
end test_sys;
 
architecture Behavioral of test_sys is 
    -- Component Declaration for the Unit Under Test (UUT)
	component openMSP430_fpga is
		Generic (
			PMEM_AWIDTH : integer := 11;
			DMEM_AWIDTH : integer := 9
		);
		Port ( 
			-- Clock Sources
	    	CLK_50MHZ : in  STD_LOGIC;
			-- Slide Switches
		    SW3       : in  STD_LOGIC;
		    SW2       : in  STD_LOGIC;
		    SW1       : in  STD_LOGIC;
		    SW0       : in  STD_LOGIC;
			-- Push Button Switches
		    BTN_EAST  : in  STD_LOGIC;
		    BTN_NORTH : in  STD_LOGIC;
		    BTN_SOUTH : in  STD_LOGIC;
		    BTN_WEST  : in  STD_LOGIC;
			-- LEDs
		    LED7      : out STD_LOGIC;
		    LED6      : out STD_LOGIC;
		    LED5      : out STD_LOGIC;
		    LED4      : out STD_LOGIC;
		    LED3      : out STD_LOGIC;
		    LED2      : out STD_LOGIC;
		    LED1      : out STD_LOGIC;
		    LED0      : out STD_LOGIC;
			-- VGA signals
			VGA_R     : out STD_LOGIC_VECTOR(3 downto 0);
			VGA_G     : out STD_LOGIC_VECTOR(3 downto 0);
			VGA_B     : out STD_LOGIC_VECTOR(3 downto 0);
			VGA_HSYNC : out STD_LOGIC;
			VGA_VSYNC : out STD_LOGIC;
			-- RS-232 Port
	    	RS232_DCE_RXD : in  STD_LOGIC;
	    	RS232_DCE_TXD : out STD_LOGIC;
			-- RS-232 Port 2
	    	RS232_DTE_RXD : in  STD_LOGIC;
	    	RS232_DTE_TXD : out STD_LOGIC;
	    	-- DAC Port
	    	DAC_OUT : out STD_LOGIC;
			-- LCD
			LCD_DB  : out STD_LOGIC_VECTOR(7 downto 0);
			LCD_E   : out STD_LOGIC;
			LCD_RS  : out STD_LOGIC;
			LCD_RW  : out STD_LOGIC
	    	 );
	end component;

	-- Local signals
	signal CLK_50MHZ	 : STD_LOGIC := '0';
	signal LED			 : STD_LOGIC_VECTOR(7 downto 0);
	signal RS232_DCE_RXD : STD_LOGIC := '1';
	signal RS232_DCE_TXD : STD_LOGIC := '1';
	signal RS232_DTE_RXD : STD_LOGIC := '1';
	signal RS232_DTE_TXD : STD_LOGIC := '1';

	signal reset : STD_LOGIC := '1';

   -- Clock period definitions
    constant CLK_period_50 : time := 20 ns; -- 50MHz
	constant BAUD_period : time := 8680 ns;	-- 115200
begin

    CLK_process_50 : process
    begin
        CLK_50MHZ <= '0';
        wait for CLK_period_50/2;
        CLK_50MHZ <= '1';
        wait for CLK_period_50/2;
    end process;

	-- Instantiate the Unit Under Test (UUT)
	uut: openMSP430_fpga port map (
		CLK_50MHZ => CLK_50MHZ,
		SW0 => '1', SW1 => '1', SW2 => '1', SW3 => '1',
		BTN_EAST => reset, BTN_NORTH => '1', BTN_SOUTH => '1', BTN_WEST => '1',
		LED0 => LED(0), LED1 => LED(1), LED2 => LED(2), LED3 => LED(3), 
		LED4 => LED(4), LED5 => LED(5), LED6 => LED(6), LED7 => LED(7), 
		VGA_R => open, VGA_G => open, VGA_B => open, VGA_HSYNC => open, VGA_VSYNC => open,
		RS232_DCE_RXD => RS232_DCE_RXD, RS232_DCE_TXD => RS232_DCE_TXD,
		RS232_DTE_RXD => RS232_DTE_RXD, RS232_DTE_TXD => RS232_DTE_TXD,
		DAC_OUT => open,
		LCD_DB => open, LCD_E => open, LCD_RS => open, LCD_RW => open
    );
	
	-- Stimulus process
	stim_proc: process
		variable I : integer range 0 to 20;
	begin	
		wait for 10 us;
		reset <= '0';
		wait for 100 us;

		-- test seemed to fail when stressing system,
		L1: loop
			exit L1 when I = 3;

			-- insert stimulus here 
			-- receive a character, LSB first
			-- 01001010 -> 0101 0010 -> 0x52 -> char 'R'
			RS232_DCE_RXD <= '0';	wait for BAUD_period;

			RS232_DCE_RXD <= '0';	wait for BAUD_period;
			RS232_DCE_RXD <= '1';	wait for BAUD_period;
			RS232_DCE_RXD <= '0';	wait for BAUD_period;
			RS232_DCE_RXD <= '0';	wait for BAUD_period;
			RS232_DCE_RXD <= '1';	wait for BAUD_period;
			RS232_DCE_RXD <= '0';	wait for BAUD_period;
			RS232_DCE_RXD <= '1';	wait for BAUD_period;
			RS232_DCE_RXD <= '0';	wait for BAUD_period;

			RS232_DCE_RXD <= '1';	wait for BAUD_period;

			I := I + 1;
		end loop;

		wait;
	end process;

end Behavioral;
