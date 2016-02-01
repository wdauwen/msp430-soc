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

library work;
use work.pkg_helpers.all;

entity tx is
	port ( CLK_SYS  : in  STD_LOGIC;
		   CLK_BAUD : in  STD_LOGIC;
		   nRESET   : in  STD_LOGIC;
		   TXD      : out STD_LOGIC;
		   tx_start : in  STD_LOGIC;
		   tx_busy  : out STD_LOGIC;
           tx_char  : in  STD_LOGIC_VECTOR (7 downto 0) );
end tx;

architecture Behavioral of tx is
	signal run, run_pulse : STD_LOGIC := '0';
	signal busy : STD_LOGIC := '0';
	signal data : STD_LOGIC_VECTOR (7 downto 0);
	
	type FSM_transmit is ( FSM_IDLE, FSM_TX_DATA, FSM_TX_STOP);
	signal fsm_state : FSM_transmit := FSM_IDLE;
begin

	fl : flancter
		port map (SET_CE => tx_start, SET_CLK => CLK_SYS,
				  CLR_CE => busy,  CLR_CLK => CLK_BAUD,
				  FLAG => run, nRESET => nRESET);

	p1 : pulse
		port map (CLK => CLK_BAUD, nRESET => nRESET,
				  SIG => run, P_FALL => open, P_RISE => run_pulse);

	tx_busy <= run or busy;

	-- send a byte out
	tx : process (nRESET, CLK_BAUD)
		variable bits : integer range 0 to 7 := 0;
	begin
		if nRESET = '0' then
			fsm_state <= FSM_IDLE;
			busy <= '0';
			TXD <= '1';
		elsif (CLK_BAUD'event and CLK_BAUD = '1') then
			case fsm_state is
				when FSM_IDLE =>
					bits := 0;
					busy <= '0';
					data <= tx_char;

					if (run_pulse = '1') then
						TXD <= '0';
						busy <= '1';
						fsm_state <= FSM_TX_DATA;
					end if;
				when FSM_TX_DATA =>
					TXD <= data(bits);
					
					if (bits = 7) then
						fsm_state <= FSM_TX_STOP;
					else
						bits := bits + 1;
					end if;
				when FSM_TX_STOP =>
					TXD <= '1';
					fsm_state <= FSM_IDLE;
			end case;
		end if;
	end process;

end Behavioral;
