library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ram_8x512_lo is
	generic (
		MEM_AWIDTH : integer := 9
	);
	port (
		addr : in  STD_LOGIC_VECTOR(MEM_AWIDTH-1 downto 0);
		dout : out STD_LOGIC_VECTOR(7 downto 0);
		din  : in  STD_LOGIC_VECTOR(7 downto 0);
		en   : in  STD_LOGIC;	-- low active
		clk  : in  STD_LOGIC;
		we   : in  STD_LOGIC	-- low active
	);	
end ram_8x512_lo;

architecture Behavioral of ram_8x512_lo is 
	type mem is array (2**MEM_AWIDTH-1 downto 0) of STD_LOGIC_VECTOR(din'range);

	function init_mem return mem is
	    variable temp_mem : mem;
	begin
	    for i in 0 to 2**MEM_AWIDTH-1 loop
	        temp_mem(i) := "00000000";
	    end loop;
	    return temp_mem;
	end;

	signal memory : mem := init_mem;

	signal addr_reg : STD_LOGIC_VECTOR(MEM_AWIDTH-1 downto 0);
begin

	process (clk)
	begin
		if (clk'event and clk = '1') then
			if (en = '0') then
				if (we = '0') then
					memory(conv_integer(addr)) <= din;
				end if;
				addr_reg <= addr;
			end if;
		end if;
	end process;

	dout <= memory(conv_integer(addr_reg));

end Behavioral;

