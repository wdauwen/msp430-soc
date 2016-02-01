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
library UNISIM;
use UNISIM.VComponents.all;

entity serial is
	port ( CLK_50MHZ  : in  STD_LOGIC;
		   TXD        : out STD_LOGIC;
		   RXD        : in  STD_LOGIC;
		   TST_BAUD   : out STD_LOGIC;
		   TST_BAUD_8 : out STD_LOGIC;
		   LED        : out STD_LOGIC_VECTOR(7 downto 0) );
end serial;

architecture Behavioral of serial is
	component baudgen is
		port ( CLK         : in  STD_LOGIC;
			   nRESET      : in  STD_LOGIC;
			   BAUD_CLK    : out STD_LOGIC;
			   BAUD_CLK_X8 : out STD_LOGIC;
	           DIV         : in  STD_LOGIC_VECTOR (4 downto 0) );
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

	component rx is
		port ( CLK_SYS     : in  STD_LOGIC;
			   CLK_BAUD_X8 : in  STD_LOGIC;
			   nRESET      : in  STD_LOGIC;
			   RXD         : in  STD_LOGIC;
			   rx_busy     : out STD_LOGIC;
			   rx_done     : out STD_LOGIC;
	           rx_char     : out STD_LOGIC_VECTOR (7 downto 0) );
	end component;

	component fifo is
		generic ( BIT_DEPTH : INTEGER := 4 );
		port ( CLK   : in  STD_LOGIC;
			   nRESET : in STD_LOGIC;
			   di    : in  STD_LOGIC_VECTOR;
			   do    : out STD_LOGIC_VECTOR;
			   wr_en : in  STD_LOGIC;
	           rd_en : in  STD_LOGIC;
           	   level : out STD_LOGIC_VECTOR (BIT_DEPTH downto 0);
			   empty : out STD_LOGIC;
			   full  : out STD_LOGIC );
	end component;

	signal cg_baudrate, cg_baudrate_x8 : STD_LOGIC := '0';
	signal baudrate, baudrate_x8 : STD_LOGIC := '0';

	signal rx_char, tx_char : STD_LOGIC_VECTOR (7 downto 0) := x"00";

	signal tx_start, tx_busy : STD_LOGIC := '0';
	signal rx_done : STD_LOGIC := '0';

	signal rd_en, empty : STD_LOGIC := '0';

	signal global_reset : STD_LOGIC := '1';
	type FSM_loopback is ( FSM_RESET, FSM_IDLE, FSM_TX_RELEASE, FSM_TX_BUSY, FSM_TX_POP );
	signal fsm_state : FSM_loopback := FSM_RESET;

	-- clock related signals
	signal clk_50M_in : STD_LOGIC;
	signal CLKFB_IN, CLK0_BUF : STD_LOGIC;
	signal dcm_clk_20M, sys_clk_20M : STD_LOGIC;
	signal dcm_clk_4M, sys_clk_4M : STD_LOGIC;
begin

	-------------------------------------------------------------------------------
	-- CLOCK GENERATION
	-------------------------------------------------------------------------------
	-- Digital Clock Manager
	-- Generate 20MHz clock from 50MHz on-board oscillator
	-- Generate 3686400Hz (+/-0.467%) clock from 50MHz on-board oscillator
	ibuf_clk_main: IBUFG port map ( O => clk_50M_in, I => CLK_50MHZ );	

	dcm_main: DCM
	generic map (
	    CLKDV_DIVIDE => 2.5,                   -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
	                                           -- 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
	    CLKFX_DIVIDE => 27,                    -- Can be any interger from 1 to 32
	    CLKFX_MULTIPLY => 2,                   -- Can be any integer from 1 to 32
	    CLKIN_DIVIDE_BY_2 => FALSE,            -- TRUE/FALSE to enable CLKIN divide by two feature
	    CLKIN_PERIOD => 20.0,                  -- Specify period of input clock
	    CLKOUT_PHASE_SHIFT => "NONE",          -- Specify phase shift of NONE, FIXED or VARIABLE
	    CLK_FEEDBACK => "1X",                  -- Specify clock feedback of NONE, 1X or 2X
	    DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
	                                           -- an integer from 0 to 15
	    DFS_FREQUENCY_MODE => "LOW",           -- HIGH or LOW frequency mode for frequency synthesis
	    DLL_FREQUENCY_MODE => "LOW",           -- HIGH or LOW frequency mode for DLL
	    DUTY_CYCLE_CORRECTION => TRUE,         -- Duty cycle correction, TRUE or FALSE
	    FACTORY_JF => X"C080",                 -- FACTORY JF Values
	    PHASE_SHIFT => 0,                      -- Amount of fixed phase shift from -255 to 255
	    SIM_MODE => "SAFE",                    -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation
	                                           -- Design Guide" for details
	    STARTUP_WAIT => FALSE)                 -- Delay configuration DONE until DCM LOCK, TRUE/FALSE
	port map (
	    CLK0 => CLK0_BUF,     -- 0 degree DCM CLK ouptput
	    CLKDV => dcm_clk_20M, -- Divided DCM CLK out (CLKDV_DIVIDE)
		CLKFX => dcm_clk_4M,  -- DCM CLK synthesis out (M/D)
--	    LOCKED => dcm_locked, -- DCM LOCK status output
	    CLKFB => CLKFB_IN,    -- DCM clock feedback
	    CLKIN => clk_50M_in,  -- Clock input (from IBUFG, BUFG or DCM)
	    PSCLK => '0',         -- Dynamic phase adjust clock input
	    PSEN => '0',          -- Dynamic phase adjust enable input
	    PSINCDEC => '0',      -- Dynamic phase adjust increment/decrement
	    RST => '0'            -- DCM asynchronous reset input
	);
	obuf_clk_fb : BUFG port map ( I => CLK0_BUF, O => CLKFB_IN );

	obuf_clk_20M : BUFG port map ( I => dcm_clk_20M, O => sys_clk_20M );
	obuf_clk_4M : BUFG port map ( I => dcm_clk_4M, O => sys_clk_4M );

	test_drive : process (sys_clk_20M)
		variable i : integer range 0 to 55 := 0;
	begin
		if (sys_clk_20M'event and sys_clk_20M = '1') then
			case fsm_state is
				when FSM_RESET =>
					if i > 50 then
						i := 0;
						fsm_state <= FSM_IDLE;
					elsif i > 40 then
						global_reset <= '1';
					elsif i	> 10 then
						global_reset <= '0';
					end if;
					i := i + 1;
				when FSM_IDLE =>
					if empty = '0' then	
						tx_start <= '1';
						fsm_state <= FSM_TX_RELEASE;
					end if;
-- WITHOUT FIFO
--					if rx_done = '1' then
--						tx_char <= rx_char;
--						tx_start <= '1';
--						fsm_state <= FSM_TX_RELEASE;
--					end if;
				when FSM_TX_RELEASE =>
					tx_start <= '0';
					fsm_state <= FSM_TX_BUSY;
				when FSM_TX_BUSY =>
					if tx_busy = '0' then
						rd_en <= '1';
						fsm_state <= FSM_TX_POP;
					end if;
				when FSM_TX_POP =>
					rd_en <= '0';
					fsm_state <= FSM_IDLE;
			end case;
		end if;
	end process;

	LED <= (others => '0'); --rx_char;
	TST_BAUD <= '0';
	TST_BAUD_8 <= '0';

	clockgen : baudgen
		port map ( CLK => sys_clk_4M, nRESET => global_reset, DIV => "00010",
				   BAUD_CLK => cg_baudrate, BAUD_CLK_X8 => cg_baudrate_x8);

	obuf_clk_baud    : BUFG port map ( I => cg_baudrate   , O => baudrate    );
	obuf_clk_baud_x8 : BUFG port map ( I => cg_baudrate_x8, O => baudrate_x8 );

	serial_tx : tx
		port map ( CLK_SYS => sys_clk_20M, CLK_BAUD => baudrate,
				   nRESET => global_reset, TXD => TXD,
				   tx_start => tx_start, tx_busy => tx_busy, tx_char => tx_char);

	serial_rx : rx
		port map ( CLK_SYS => sys_clk_20M, CLK_BAUD_X8 => baudrate_x8,
				   nRESET => global_reset, RXD => RXD,
				   rx_busy => open, rx_done => rx_done, rx_char => rx_char);
	
	rx_fifo : fifo
		generic map ( BIT_DEPTH => 4 )
		port map ( CLK => sys_clk_20M, nRESET => global_reset, 
			       di => rx_char, do => tx_char,
				   wr_en => rx_done, rd_en => rd_en, 
				   empty => empty, full => open, level => open);

end Behavioral;
