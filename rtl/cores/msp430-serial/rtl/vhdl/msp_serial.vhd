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

entity msp_serial is
	generic (  ENABLE_LOOPBACK : boolean := false
			);
	port   ( 
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
end msp_serial;

architecture Behavioral of msp_serial is
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
			   tx_start : in  STD_LOGIC;
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
		generic ( BIT_DEPTH : INTEGER );
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

	signal nRST_I : STD_LOGIC := '0';
	signal baudrate, baudrate_x8 : STD_LOGIC := '0';

	signal tx_start, lb_tx_start, wb_tx_start : STD_LOGIC := '0';
	signal wb_tx_char, lb_tx_char, tx_char : STD_LOGIC_VECTOR (7 downto 0) := x"00";

	signal rx_char, rx_fifo, rx_data : STD_LOGIC_VECTOR (7 downto 0) := x"00";
	signal rx_done, wb_rx_clear, rx_push : STD_LOGIC := '0';
	signal rx_pop, wb_rx_pop, lb_rx_pop : STD_LOGIC := '0';

	type FSM_loopback is ( FSM_IDLE, FSM_TX_RELEASE, FSM_TX_BUSY, FSM_TX_POP );
	signal fsm_state : FSM_loopback := FSM_IDLE;

	-- register interfaces
	signal reg_rd     : STD_LOGIC_VECTOR(15 downto 0);

	signal reg_status : STD_LOGIC_VECTOR(15 downto 0) := x"0000";
	alias tx_busy     is reg_status(0);
	alias rx_busy     is reg_status(1);
	alias rx_done_lvl is reg_status(2);
	alias fifo_empty  is reg_status(3);
	alias fifo_full   is reg_status(4);
	alias fifo_en     is reg_status(7);
	alias loopback    is reg_status(8);
	signal reg_level  : STD_LOGIC_VECTOR( 7 downto 0) := (others => '0');
	signal reg_baud   : STD_LOGIC_VECTOR( 4 downto 0) := "00010";
		-- BAUDRATE DIVIDER
		--  2 : 115200
		--  6 : 38400
		-- 12 : 19200
		-- 24 : 9600
begin

	-- Register mux
	WB_READ : process (CLK_I)
	begin
		if (CLK_I'event and CLK_I = '0') then
			case ADR_I is
				when "00"   => reg_rd <= reg_status;
				when "01"   => reg_rd <= "00000000" & rx_data;
				when "10"   => reg_rd <= "00000000" & reg_level;
				when "11"   => reg_rd <= "00000000000" & reg_baud;
				when others => reg_rd <= (others => '0');
			end case;
		end if;
	end process;

	WB_READ_FLAGS : process (CLK_I)
	begin
		if (CLK_I'event and CLK_I = '1') then
			wb_rx_clear <= '0';
			if (STB_I = '1' and WE_I = '0') then
				case ADR_I is
					when "01"   => wb_rx_clear <= '1';
					when others => NULL;
				end case;
			end if;
		end if;
	end process;

	DAT_O <= reg_rd when (STB_I = '1' and WE_I = '0') else (others => '0');
	
	wb_write_lb : if (ENABLE_LOOPBACK) generate
		WB_WRITE : process (CLK_I)
		begin
			if (CLK_I'event and CLK_I = '0') then
				wb_tx_start <= '0';
				if STB_I = '1' and WE_I = '1' and SEL_I = "11" then
					case ADR_I is
						when "00"   => fifo_en  <= DAT_I(7);
									   loopback <= DAT_I(8);
						when "01"   => wb_tx_char  <= DAT_I( 7 downto 0);
									   wb_tx_start <= '1';
						when "11"   => reg_baud <= DAT_I( 4 downto 0);
						when others => null;
					end case;
				end if;
			end if;
		end process;
	end generate;

	wb_write : if (not ENABLE_LOOPBACK) generate
		WB_WRITE : process (CLK_I)
		begin
			if (CLK_I'event and CLK_I = '0') then
				wb_tx_start <= '0';
				if STB_I = '1' and WE_I = '1' and SEL_I = "11" then
					case ADR_I is
						when "00"   => fifo_en  <= DAT_I(7);
						when "01"   => wb_tx_char  <= DAT_I( 7 downto 0);
									   wb_tx_start <= '1';
						when "11"   => reg_baud <= DAT_I( 4 downto 0);
						when others => null;
					end case;
				end if;
			end if;
		end process;
	end generate;

	update_status : process(CLK_I)
	begin
		if (CLK_I'event and CLK_I = '1') then
			wb_rx_pop <= '0';

			-- clear flag if read
			if wb_rx_clear = '1' then
				rx_done_lvl <= '0';
				if fifo_en = '1' then
					wb_rx_pop <= '1';
				end if;
			end if;

			-- create level signal from edge
			if rx_done = '1' then
				rx_done_lvl <= '1';
			end if;
		end if;
	end process;

	lb : if (ENABLE_LOOPBACK) generate
		test_drive : process (loopback, CLK_I)
		begin
			if loopback = '0' then
				fsm_state <= FSM_IDLE;
			elsif (CLK_I'event and CLK_I = '1') then
				case fsm_state is
					when FSM_IDLE =>
						lb_tx_char <= rx_data;
						-- WITH FIFO
						if fifo_en = '1' and fifo_empty = '0' then	
							lb_tx_start <= '1';
							fsm_state <= FSM_TX_RELEASE;
						end if;
						-- WITHOUT FIFO
						if fifo_en = '0' and rx_done = '1' then
							lb_tx_start <= '1';
							fsm_state <= FSM_TX_RELEASE;
						end if;
					when FSM_TX_RELEASE =>
						lb_tx_start <= '0';
						fsm_state <= FSM_TX_BUSY;
					when FSM_TX_BUSY =>
						if tx_busy = '0' then
							if fifo_en = '0' then
								fsm_state <= FSM_IDLE;
							else
								lb_rx_pop <= '1';
								fsm_state <= FSM_TX_POP;
							end if;
						end if;
					when FSM_TX_POP =>
						lb_rx_pop <= '0';
						fsm_state <= FSM_IDLE;
				end case;
			end if;
		end process;
	end generate;

	nRST_I <= not RST_I;

	tx_char  <= wb_tx_char  when (loopback = '0') else lb_tx_char;
	tx_start <= wb_tx_start when (loopback = '0') else lb_tx_start;	

	rx_data <= rx_char when (fifo_en = '0') else rx_fifo;
	rx_push <= rx_done and fifo_en;
	rx_pop  <= wb_rx_pop when (loopback = '0') else lb_rx_pop;

	serial_rx_fifo : fifo
		generic map ( BIT_DEPTH => 7 )
		port map ( CLK => CLK_I, nRESET => nRST_I, 
			       di => rx_char, do => rx_fifo,
				   wr_en => rx_push, rd_en => rx_pop, 
				   level => reg_level, empty => fifo_empty, full => fifo_full);

	clockgen : baudgen
		port map ( CLK => CLK_BAUDGEN, nRESET => nRST_I, DIV => reg_baud,
				   BAUD_CLK => baudrate, BAUD_CLK_X8 => baudrate_x8);

	serial_tx : tx
		port map ( CLK_SYS => CLK_I, CLK_BAUD => baudrate,
				   nRESET => nRST_I, TXD => TXD,
				   tx_start => tx_start, tx_busy => tx_busy, tx_char => tx_char);

	serial_rx : rx
		port map ( CLK_SYS => CLK_I, CLK_BAUD_X8 => baudrate_x8,
				   nRESET => nRST_I, RXD => RXD,
				   rx_busy => rx_busy, rx_done => rx_done, rx_char => rx_char);

end Behavioral;
