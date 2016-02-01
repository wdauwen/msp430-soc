--
-- This file implements a very simple clock divisor.
-- Input clock is 16 MHz and is divided by 8,000,000 so we get a period of
-- 1 second.
-- The code is abstracted and isn't tied to a particular device.
--
-- Author: Salvador E. Tropea
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Led is
   port(
      clk_i : in  std_logic;  -- Clock
      led_o : out std_logic); -- Output for the blinking led

constant XTAL : integer:=16000000;
constant BITS : integer:=23;

end entity Led;

architecture Correcta of Led is
   subtype  cnttype is unsigned(BITS-1 downto 0);
   constant MAXVAL : cnttype:=to_unsigned(XTAL/2,BITS);
   signal   ast    : std_logic:='0'; -- We assume the FPGA have a reset
begin
   -- Clock divisor
   clock_div:
   process (clk_i)
      -- We assume the FPGA have a reset
      variable conta : cnttype:=(others => '0');
   begin
      if rising_edge(clk_i) then
         conta:=conta+1;
         if conta=MAXVAL then
            conta:=(others => '0');
            ast  <= not(ast);
         end if;
      end if;
   end process clock_div;
   
   -- Output assignment
   led_o <= ast;
end architecture Correcta;


