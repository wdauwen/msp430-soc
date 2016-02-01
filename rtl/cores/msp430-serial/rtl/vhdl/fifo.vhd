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

entity fifo is
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
end fifo;

architecture Behavioral of fifo is
	type mem is array (2**BIT_DEPTH-1 downto 0) of STD_LOGIC_VECTOR (di'range);
	signal memory : mem;

	signal pntr_rd, pntr_wr : STD_LOGIC_VECTOR (BIT_DEPTH-1 downto 0);
	signal word_count : STD_LOGIC_VECTOR (level'range);
begin

	do <= memory(CONV_INTEGER(pntr_rd));
	
	level <= word_count;

	flags : process(CLK)
	begin
		if (CLK'event and CLK = '0') then
			full <= word_count(word_count'left);

			empty <= '0';
			if (CONV_INTEGER(word_count) = 0) then
				empty <= '1';
			end if;
		end if;
	end process;

	fifo : process(nRESET, CLK)
	begin
		if (nRESET = '0') then
			pntr_rd <= (others => '0');
			pntr_wr <= (others => '0');
			word_count <= (others => '0');
		elsif (CLK'event and CLK = '1') then
			if ( wr_en = '1' and word_count(word_count'left) = '0' ) then
				-- store a new word
				memory(CONV_INTEGER(pntr_wr)) <= di;
				word_count <= word_count + 1;
				pntr_wr <= pntr_wr + 1;
			end if;

			if ( rd_en = '1' and not (word_count = "00000") ) then
				-- read a word
				word_count <= word_count - 1;
				pntr_rd <= pntr_rd + 1;
			end if;
		end if;
	end process;

end Behavioral;
