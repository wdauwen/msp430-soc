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

entity msp_gpio is
	port   ( 
	           port_in    : in  STD_LOGIC_VECTOR( 7 downto 0);
    		   port_out   : out STD_LOGIC_VECTOR( 7 downto 0);
    		   port_dir   : out STD_LOGIC_VECTOR( 7 downto 0);
    		   -- WISHBONE BUS
    		   RST_I      : in  STD_LOGIC;
    		   CLK_I      : in  STD_LOGIC;                    
               ADR_I      : in  STD_LOGIC_VECTOR( 1 downto 0);
    		   DAT_I      : in  STD_LOGIC_VECTOR(15 downto 0);
               DAT_O      : out STD_LOGIC_VECTOR(15 downto 0);
    		   WE_I       : in  STD_LOGIC;
               SEL_I      : in  STD_LOGIC_VECTOR( 1 downto 0);
               STB_I      : in  STD_LOGIC 
            );
end msp_gpio;

architecture Behavioral of msp_gpio is
    signal reg_rd : STD_LOGIC_VECTOR( 7 downto 0);
	
	-- register interfaces
	signal reg_out : STD_LOGIC_VECTOR( 7 downto 0);
	signal reg_dir : STD_LOGIC_VECTOR( 7 downto 0);
begin
	-- Register mux
	WB_READ : process (CLK_I)
	begin
		if (CLK_I'event and CLK_I = '0') then
			case ADR_I is
				when "00"   => reg_rd <= port_in;
				when "01"   => reg_rd <= reg_out;
                when "10"   => reg_rd <= reg_dir;
				when others => reg_rd <= (others => '0');
			end case;
		end if;
	end process;
	
	DAT_O <= "00000000" & reg_rd when (STB_I = '1' and WE_I = '0') else (others => '0');
	
	WB_WRITE : process (CLK_I)
	begin
		if (CLK_I'event and CLK_I = '0') then
            if (RST_I = '1') then
    		    reg_out <= (others => '0');
    		    reg_dir <= (others => '0');
			elsif STB_I = '1' and WE_I = '1' and SEL_I = "11" then
				case ADR_I is
					when "01"   => reg_out <= DAT_I(7 downto 0);
                    when "10"   => reg_dir <= DAT_I(7 downto 0);
					when others => null;
				end case;
			end if;
		end if;
	end process;

    -- map on the outputs
    port_out <= reg_out;
    port_dir <= reg_dir;

    -- room for improvements
    --  - generate interrupts
    --  - pullup / pulldown
    --  - alternate functions
    --  - ...

end Behavioral;
