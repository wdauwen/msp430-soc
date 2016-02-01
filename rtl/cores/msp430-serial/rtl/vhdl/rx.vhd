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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.pkg_helpers.all;

entity rx is
	port ( CLK_SYS     : in  STD_LOGIC;
		   CLK_BAUD_X8 : in  STD_LOGIC;
		   nRESET      : in  STD_LOGIC;
		   RXD         : in  STD_LOGIC;
		   rx_busy     : out STD_LOGIC;
		   rx_done     : out STD_LOGIC;
           rx_char     : out STD_LOGIC_VECTOR (7 downto 0) );
end rx;

architecture Behavioral of rx is
	signal rxd_synced : STD_LOGIC;
	signal done, done_synced : STD_LOGIC := '0';
	signal char : STD_LOGIC_VECTOR (7 downto 0);

	signal capture_rst, capture, capture_en, capture_next : STD_LOGIC := '0';
	signal rxd_synced_fall : STD_LOGIC := '0';
	signal capture_resync : STD_LOGIC_VECTOR(2 downto 0);
	type FSM_receive is ( FSM_IDLE, FSM_RX_START, FSM_RX_DATA, FSM_RX_STOP);
	signal fsm_state : FSM_receive := FSM_IDLE;
begin
	
	s1 : resync
		generic map (LEVEL_IN_RESET => '1')
		port map (CLK => CLK_BAUD_X8, nRESET => nRESET, 
				  SIG_IN => RXD, SIG_OUT => rxd_synced);
	p1 : pulse
		port map (CLK => CLK_BAUD_X8, nRESET => nRESET,
				  SIG => rxd_synced, P_FALL => rxd_synced_fall, P_RISE => open);

	s2 : resync
		port map (CLK => CLK_SYS, nRESET => nRESET, 
				  SIG_IN => done, SIG_OUT => done_synced);
	p2 : pulse
		port map (CLK => CLK_SYS, nRESET => nRESET,
				  SIG => done_synced, P_FALL => open, P_RISE => rx_done);

	rx_busy <= capture;

	rx_capture_resync : process (rxd_synced_fall, CLK_BAUD_X8)
	begin
		if rxd_synced_fall = '1' then
			capture_resync <= "001";
		elsif CLK_BAUD_X8'event and CLK_BAUD_X8 = '0' then
			capture_resync <= capture_resync + 1;
		end if;
	end process;

	capture_rst <= not nRESET or not capture;

	rx_capture : process (capture_rst, CLK_BAUD_X8)
	begin
		if capture_rst = '1' then
			capture_en <= '0';
			capture_next <= '0';
		elsif CLK_BAUD_X8'event and CLK_BAUD_X8 = '1' then
			capture_en <= '0';
			capture_next <= '0';

			if (UNSIGNED(capture_resync) = 3) then
				capture_en <= '1';
			end if;

			if (UNSIGNED(capture_resync) = 5) then
				capture_next <= '1';
			end if;
		end if;
	end process;

	rx_sample : process (nRESET, CLK_BAUD_X8)
		variable bits : integer range 0 to 10 := 0;
	begin
		if nRESET = '0' then
			fsm_state <= FSM_IDLE;
			done <= '0';
			char <= x"00";
			rx_char <= x"00";
		elsif CLK_BAUD_X8'event and CLK_BAUD_X8 = '1' then
			done <= '0';

			case fsm_state is
				when FSM_IDLE =>
					if (rxd_synced = '0') then
						capture <= '1';
						fsm_state <= FSM_RX_START;
					end if;
				when FSM_RX_START =>
					bits := 0;
					if (capture_next = '1') then
						fsm_state <= FSM_RX_DATA;
					end if;
				when FSM_RX_DATA =>
					if (capture_en = '1') then 
						char(bits) <= rxd_synced;
					end if;

					if (capture_next = '1') then
						if (bits = 7) then
							fsm_state <= FSM_RX_STOP;
						end if;
						bits := bits + 1;
					end if; 
				when FSM_RX_STOP =>
					if (capture_en = '1') then
						rx_char <= char;
					end if;

					if (capture_next = '1') then
						done <= '1';
						capture <= '0';
						fsm_state <= FSM_IDLE;
					end if;
			end case;
		end if;
	end process;

end Behavioral;
