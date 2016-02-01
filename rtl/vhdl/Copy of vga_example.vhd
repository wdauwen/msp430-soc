
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity msp_vga is
	Port	( 
    			vga_clk_50M : in  STD_LOGIC;
				vga_hsync   : out STD_LOGIC;
				vga_vsync   : out STD_LOGIC;
				vga_red     : out STD_LOGIC_VECTOR(3 downto 0);
				vga_green   : out STD_LOGIC_VECTOR(3 downto 0);
				vga_blue    : out STD_LOGIC_VECTOR(3 downto 0);
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
end msp_vga;

architecture Behavioral of msp_vga is
	signal reg_rd : STD_LOGIC_VECTOR(15 downto 0);
	
	-- register interfaces
	signal reg_1 : STD_LOGIC_VECTOR(15 downto 0);
	signal reg_2 : STD_LOGIC_VECTOR(15 downto 0);
	signal reg_3 : STD_LOGIC_VECTOR(15 downto 0);

	signal vga_clk : STD_LOGIC := '0';
begin
	-- Register mux
	WB_READ : process (CLK_I)
	begin
		if (CLK_I'event and CLK_I = '0') then
			case ADR_I is
				when "00"    => reg_rd <= reg_1;
				when "01"    => reg_rd <= reg_2;
				when "10"    => reg_rd <= reg_3;
				when others  => reg_rd <= (others => '0');
			end case;
		end if;
	end process;
	
	DAT_O <= reg_rd when (STB_I = '1' and WE_I = '0') else (others => '0');

	WB_WRITE : process (CLK_I)
	begin
		if (CLK_I'event and CLK_I = '0') then
			if STB_I = '1' and WE_I = '1' and SEL_I = "11" then
				case ADR_I is
					when "00"   => reg_1 <= DAT_I;
					when "01"   => reg_2 <= DAT_I;
					when "10"   => reg_3 <= DAT_I;
					when others => null;
				end case;
			end if;
		end if;
	end process;

------------------------------------------------------------------------------
-- VGA example
------------------------------------------------------------------------------

process (vga_clk_50M)
begin
	if vga_clk_50M'event and vga_clk_50M = '1' then
		vga_clk <= not vga_clk;
	end if;	
end process;

process (vga_clk)
	variable xH : integer := 0;
	variable xV : integer := 0;
begin
	if vga_clk'event and vga_clk ='1' then

		-- HSYNC PULSE
		if xH = 0 then vga_hsync <= '0'; end if;
		if xH > 96 then vga_hsync <= '1'; end if;

		-- VSYNC PULSE
		if xV = 0 then vga_vsync <= '0'; end if;
		if xV > 2 then vga_vsync <= '1'; end if;

		
		xH := xH + 1;
		
		if (xH = 800) then
			xH := 0;
			xV := xV + 1;
		end if;
		
		if (xV = 520) then
			xV := 0;
		end if;

		-- color draw
		if (xH > 144 and xH < 144+320 and xV > 31 and xV <= 31+240) then
			vga_red <= reg_1(11 downto 8);	vga_green <= reg_1(7 downto 4);	vga_blue <= reg_1(3 downto 0);
		elsif (xH > 144 and xH < 144+640 and xV > 31 and xV <= 31+240) then
			vga_red <= "1111";	vga_green <= "0000";	vga_blue <= "0000";	
		elsif (xH > 144 and xH < 144+320 and xV >= 31+241 and xV < 31+480) then
			vga_red <= "0000";	vga_green <= "1111";	vga_blue <= "0000";
		elsif (xH > 144 and xH < 144+640 and xV >= 31+241 and xV < 31+480) then
			vga_red <= "1111";	vga_green <= "0000";	vga_blue <= "1111";	
		else
			vga_red <= "0000";	vga_green <= "0000";	vga_blue <= "0000";	
		end if;

	end if;
end process;
				
end Behavioral;

