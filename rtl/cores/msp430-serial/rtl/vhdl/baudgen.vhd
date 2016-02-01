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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity baudgen is
	port ( CLK         : in  STD_LOGIC;
		   nRESET      : in  STD_LOGIC;
		   BAUD_CLK    : out STD_LOGIC;
		   BAUD_CLK_X8 : out STD_LOGIC;
           DIV         : in  STD_LOGIC_VECTOR (4 downto 0) );
end baudgen;

architecture Behavioral of baudgen is
	signal baud_ref_x8 : STD_LOGIC := '0';
	signal baud : std_logic_vector(3 downto 0) := "0000";
begin

	BAUD_CLK <= baud(3);
	BAUD_CLK_X8 <= baud_ref_x8;

	clk_115200x8 : process (CLK, nRESET)
		variable i : integer range 0 to 32 := 0;
	begin
		if (nRESET = '0') then
			i := 0;
			baud_ref_x8 <= '0';
			baud <= "0000";
		elsif (CLK'event and CLK='1') then
			i := i + 1;
			if (i = CONV_INTEGER(DIV)) then
				i := 0;
			end if;

			if (i = 0) then
				baud_ref_x8 <= not baud_ref_x8;
				baud <= baud + 1;
			end if;
		end if;
	end process;

end Behavioral;
