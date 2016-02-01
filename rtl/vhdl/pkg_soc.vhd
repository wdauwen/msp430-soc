library IEEE;
use IEEE.STD_LOGIC_1164.all;

package pkg_soc is

component ram_8bit is
	generic (
		MEM_AWIDTH : integer
	);
	port (
		addr : in  STD_LOGIC_VECTOR(MEM_AWIDTH-1 downto 0);
		dout : out STD_LOGIC_VECTOR(7 downto 0);
		din  : in  STD_LOGIC_VECTOR(7 downto 0);
		en   : in  STD_LOGIC;	-- low active
		clk  : in  STD_LOGIC;
		we   : in  STD_LOGIC	-- low active
	);	
end component;

component openMSP430 is
	Port (
	-- OUTPUTs
	aclk         : out STD_LOGIC;                     -- ASIC ONLY: ACLK
    aclk_en      : out STD_LOGIC;                     -- FPGA ONLY: ACLK enable 
    dbg_freeze   : out STD_LOGIC;                     -- Freeze peripherals
    dbg_uart_txd : out STD_LOGIC;                     -- Debug interface: UART TXD
    dco_enable   : out STD_LOGIC;                     -- ASIC ONLY: Fast oscillator enable
    dco_wkup     : out STD_LOGIC;                     -- ASIC ONLY: Fast oscillator wake-up (asynchronous)
    dmem_addr    : out STD_LOGIC_VECTOR;              -- Data Memory address
    dmem_cen     : out STD_LOGIC;                     -- Data Memory chip enable (low active)
    dmem_din     : out STD_LOGIC_VECTOR(15 downto 0); -- Data Memory data input
    dmem_wen     : out STD_LOGIC_VECTOR( 1 downto 0); -- Data Memory write enable (low active)
    irq_acc      : out STD_LOGIC_VECTOR(13 downto 0); -- Interrupt request accepted (one-hot signal)
    lfxt_enable  : out STD_LOGIC;                     -- ASIC ONLY: Low frequency oscillator enable
    lfxt_wkup    : out STD_LOGIC;                     -- ASIC ONLY: Low frequency oscillator wake-up (asynchronous)
    mclk         : out STD_LOGIC;                     -- Main system clock
    per_addr     : out STD_LOGIC_VECTOR(13 downto 0); -- Peripheral address
    per_din      : out STD_LOGIC_VECTOR(15 downto 0); -- Peripheral data input
    per_we       : out STD_LOGIC_VECTOR( 1 downto 0); -- Peripheral write enable (high active)
    per_en       : out STD_LOGIC;                     -- Peripheral enable (high active)
    pmem_addr    : out STD_LOGIC_VECTOR;              -- Program Memory address
    pmem_cen     : out STD_LOGIC;                     -- Program Memory chip enable (low active)
    pmem_din     : out STD_LOGIC_VECTOR(15 downto 0); -- Program Memory data input (optional)
    pmem_wen     : out STD_LOGIC_VECTOR( 1 downto 0); -- Program Memory write enable (low active) (optional)
    puc_rst      : out STD_LOGIC;                     -- Main system reset
    smclk        : out STD_LOGIC;                     -- ASIC ONLY: SMCLK
    smclk_en     : out STD_LOGIC;                     -- FPGA ONLY: SMCLK enable
	-- INPUTs
    cpu_en       : in  STD_LOGIC;                     -- Enable CPU code execution (asynchronous and non-glitchy)
    dbg_en       : in  STD_LOGIC;                     -- Debug interface enable (asynchronous and non-glitchy)
    dbg_uart_rxd : in  STD_LOGIC;                     -- Debug interface: UART RXD
    dco_clk      : in  STD_LOGIC;                     -- Fast oscillator (fast clock)
    dmem_dout    : in  STD_LOGIC_VECTOR(15 downto 0); -- Data Memory data output
    irq          : in  STD_LOGIC_VECTOR(13 downto 0); -- Maskable interrupts
    lfxt_clk     : in  STD_LOGIC;                     -- Low frequency oscillator (typ 32kHz)
    nmi          : in  STD_LOGIC;                     -- Non-maskable interrupt (asynchronous)
    per_dout     : in  STD_LOGIC_VECTOR(15 downto 0); -- Peripheral data output
    pmem_dout    : in  STD_LOGIC_VECTOR(15 downto 0); -- Program Memory data output
    reset_n      : in  STD_LOGIC;                     -- Reset Pin (low active)
    scan_enable  : in  STD_LOGIC;                     -- ASIC ONLY: Scan enable (active during scan shifting)
    scan_mode    : in  STD_LOGIC;                     -- ASIC ONLY: Scan mode
    wkup         : in  STD_LOGIC                      -- ASIC ONLY: System Wake-up (asynchronous and non-glitchy)
	     );
end component;

component msp_vga is
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
end component;

component msp_serial is
    port   ( 
               -- UART signals
               CLK_BAUDGEN : in  STD_LOGIC;
               TXD         : out STD_LOGIC;
               RXD         : in  STD_LOGIC;
               -- WISHBONE BUS
               RST_I       : in  STD_LOGIC;
               CLK_I       : in  STD_LOGIC;                    
               ADR_I       : in  STD_LOGIC_VECTOR( 1 downto 0);
               DAT_I       : in  STD_LOGIC_VECTOR(15 downto 0);
               DAT_O       : out STD_LOGIC_VECTOR(15 downto 0);
               WE_I        : in  STD_LOGIC;
               SEL_I       : in  STD_LOGIC_VECTOR( 1 downto 0);
               STB_I       : in  STD_LOGIC 
            );
end component;

component msp_gpio is
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
end component;

component msp_dac is
    port   ( 
               CLK_50MHZ  : in  STD_LOGIC;
               A_OUT      : out STD_LOGIC;
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
end component;

component msp_lcd is
	port   ( 
	           lcd_db     : out STD_LOGIC_VECTOR( 7 downto 0);
    		   lcd_e      : out STD_LOGIC;
    		   lcd_rs     : out STD_LOGIC;
               lcd_rw     : out STD_LOGIC;
    		   -- WISHBONE BUS
    		   RST_I      : in  STD_LOGIC;
    		   CLK_I      : in  STD_LOGIC;                    
               ADR_I      : in  STD_LOGIC_VECTOR( 4 downto 0);
    		   DAT_I      : in  STD_LOGIC_VECTOR(15 downto 0);
               DAT_O      : out STD_LOGIC_VECTOR(15 downto 0);
    		   WE_I       : in  STD_LOGIC;
               SEL_I      : in  STD_LOGIC_VECTOR( 1 downto 0);
               STB_I      : in  STD_LOGIC 
            );
end component;

component msp_ethernet is
    port   ( 
               E_MDC      : out STD_LOGIC;
    		   E_MDIO_I   : in  STD_LOGIC;
               E_MDIO_O   : out STD_LOGIC;
               E_MDIO_T   : out STD_LOGIC;
               E_NRST     : out STD_LOGIC;
			   E_TXD      : out STD_LOGIC_VECTOR(4 downto 0);
			   E_TX_CLK   : in  STD_LOGIC;
			   E_TX_EN    : out STD_LOGIC;
               -- WISHBONE BUS
               RST_I      : in  STD_LOGIC;
               CLK_I      : in  STD_LOGIC;                    
               ADR_I      : in  STD_LOGIC_VECTOR( 2 downto 0);
               DAT_I      : in  STD_LOGIC_VECTOR(15 downto 0);
               DAT_O      : out STD_LOGIC_VECTOR(15 downto 0);
               WE_I       : in  STD_LOGIC;
               SEL_I      : in  STD_LOGIC_VECTOR( 1 downto 0);
               STB_I      : in  STD_LOGIC 
            );
end component;

end pkg_soc;
