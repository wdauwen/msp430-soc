--
-- This code interconnects our component with the real world.
-- That's Xilinx specific and isn't like a testbench.
--
-- Author: Salvador E. Tropea
--
-- Definitions for this board
use work.AvnetS3AEval.all;
library IEEE;
use IEEE.std_logic_1164.all;

entity LedTop is
   -- The "Top Level" ports are mapped to real I/O pins. If we don't do this
   -- mapping the tool will choose random pins and this is hardly what we
   -- need.
   port(
      clk_i : in  std_logic;  -- Clock
      led_o : out std_logic); -- Output for the blinking led
   
   -- This is how we assign FPGA pins to ports.
   -- This code can be compiled with any tool, but only Xilinx compatible
   -- tools will understand the attributes.
   attribute LOC        : string;
   -- That's a special pin designed to distribute clocks.
   attribute LOC of clk_i : signal is BRD_CLK_I;
   -- Led: P17, board's led 1.
   attribute LOC of led_o : signal is BRD_LED1_O;
end entity LedTop;

architecture Xilinx of LedTop is
   -- Component declaration. In a real project it goes inside a package.
   component Led is
      port(
         clk_i : in  std_logic;  -- Clock
         led_o : out std_logic); -- Output for the blinking led
   end component Led;
begin
   -- Component instantiation
   Divisor: Led
      port map(clk_i => clk_i, led_o => led_o);
end architecture Xilinx;


