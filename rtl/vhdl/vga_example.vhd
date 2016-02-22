
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
	signal clkdiv2, hscreen, vscreen, onscreen, enable, xpos, ypos : STD_LOGIC;
    signal red, green, blue : STD_LOGIC_VECTOR (3 downto 0) := "0000";
	
	-- register interfaces
	signal reg_1 : STD_LOGIC_VECTOR(15 downto 0);
	signal reg_2 : STD_LOGIC_VECTOR(15 downto 0);
	signal reg_3 : STD_LOGIC_VECTOR(15 downto 0);

	signal vga_clk : STD_LOGIC := '0';
	
	alias clk is vga_clk_50M;
	alias hso is vga_hsync;
	alias vso is vga_vsync;
    alias ro is vga_red;
	alias go is vga_green;
    alias bo is vga_blue;
	
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
-- VGA Willem
------------------------------------------------------------------------------

        P_clkdiv2: process(clk)
                begin
                    if clk'event and clk = '1' then
                        clkdiv2 <= not clkdiv2;
                    end if;
                end process;
                
        hsdiv: process(clkdiv2)
            variable x : INTEGER := 0;
        begin
            if clkdiv2'event and clkdiv2 = '1' then
                x := x + 1;
                if x = 800 then
                    x := 0;
                end if;
                if x < 96 then
                    hso <= '0';
                else
                    hso <= '1';
                end if ;
                if x > 112 and x < 112+640 then
                    hscreen <= '1';
                else 
                    hscreen <= '0';
                end if;
                if x = 799 then
                    enable <= '1';
                else 
                    enable <= '0';
                end if;     
            end if;
        end process;
                
        vsdiv: process (clkdiv2)
            variable x : INTEGER := 0;
        begin
            if clkdiv2'event and clkdiv2 = '1' then  
                if enable = '1' then
                    x := x + 1;
                    if x = 521 then
                        x := 0;
                    end if;
                    if x < 2 then
                        vso <= '0';
                    else 
                        vso <= '1';
                    end if ;
                        
                    if x > 12 and x < 12+480 then
                        vscreen <= '1';
                    else 
                        vscreen <= '0';
                    end if;
                end if;
            end if;
        end process;
        
        figuur: process (clkdiv2)
            variable xpos : natural range 0 to 300000000 := 0;
            variable ypos :natural range 0 to 300000000 := 0;
            variable baly : integer := 320;
            variable balx : integer := 180;
            variable pady : integer := 320;
            variable padx : integer := 50;
                        
        begin
            if clkdiv2'event and clkdiv2 = '1' then     
                if onscreen = '1' then
                    xpos := xpos +1;
                else
                    xpos := 0;
                end if;
                
                if xpos = 639 then
                    ypos := ypos + 1;
                end if;
                if vscreen = '0' then
                    ypos := 0;
                end if;
                red <= "0000";
                green <= "0000";
                blue <= "0000";
                pady := conv_integer(reg_3);
                if (xpos > padx and xpos < padx+10) and (ypos > pady and ypos < pady+60) then
                    red <= "0000";
                    green <= "1111";
                    blue <= "0000";
                end if;
                baly := conv_integer(reg_1);
                balx := conv_integer(reg_2);
                if (xpos > balx and xpos < balx+10) and (ypos > baly and ypos < baly+10) then
                    red <= "1111";
                    green <= "0000";
                    blue <= "0000";                   
                end if;  
                if onscreen = '0' then
                    red <= "0000";
                    green <= "0000";
                    blue <= "0000";
                end if;
            end if;
        end process;
        
        onscreen <= vscreen and hscreen;
        ro <= red and onscreen&onscreen&onscreen&onscreen;
        go <= green and onscreen&onscreen&onscreen&onscreen;
        bo <= blue and onscreen&onscreen&onscreen&onscreen;
        		
end Behavioral;

