library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.pkg_soc.all;

entity openMSP430_fpga is
	Generic (
		PMEM_AWIDTH : integer := 12;
		DMEM_AWIDTH : integer := 9
	);
	Port ( 
		-- Clock Sources
    	CLK_50MHZ : in  STD_LOGIC;
		-- Slide Switches
	    SW3       : in  STD_LOGIC;
	    SW2       : in  STD_LOGIC;
	    SW1       : in  STD_LOGIC;
	    SW0       : in  STD_LOGIC;
		-- Push Button Switches
	    BTN_EAST  : in  STD_LOGIC;
	    BTN_NORTH : in  STD_LOGIC;
	    BTN_SOUTH : in  STD_LOGIC;
	    BTN_WEST  : in  STD_LOGIC;
		-- LEDs
	    LED7      : out STD_LOGIC;
	    LED6      : out STD_LOGIC;
	    LED5      : out STD_LOGIC;
	    LED4      : out STD_LOGIC;
	    LED3      : out STD_LOGIC;
	    LED2      : out STD_LOGIC;
	    LED1      : out STD_LOGIC;
	    LED0      : out STD_LOGIC;
		-- VGA signals
		VGA_R     : out STD_LOGIC_VECTOR(3 downto 0);
		VGA_G     : out STD_LOGIC_VECTOR(3 downto 0);
		VGA_B     : out STD_LOGIC_VECTOR(3 downto 0);
		VGA_HSYNC : out STD_LOGIC;
		VGA_VSYNC : out STD_LOGIC;
		-- RS-232 Port
    	RS232_DCE_RXD : in  STD_LOGIC;
    	RS232_DCE_TXD : out STD_LOGIC;
		-- RS-232 Port 2
    	RS232_DTE_RXD : in  STD_LOGIC;
    	RS232_DTE_TXD : out STD_LOGIC;
    	-- DAC Port
    	DAC_OUT : out STD_LOGIC;
		-- LCD
		LCD_DB  : out STD_LOGIC_VECTOR(7 downto 0);
		LCD_E   : out STD_LOGIC;
		LCD_RS  : out STD_LOGIC;
		LCD_RW  : out STD_LOGIC;
		-- ETHERNET
        E_NRST   : out STD_LOGIC;
		E_MDC    : out STD_LOGIC;
		E_MDIO   : inout STD_LOGIC;
	    E_TXD    : out STD_LOGIC_VECTOR(4 downto 0);
	    E_TX_CLK : in  STD_LOGIC;
	    E_TX_EN  : out STD_LOGIC
    	 );
end openMSP430_fpga;
	
architecture Behavioral of openMSP430_fpga is	

-------------------------------------------------------------------------------
-- 1)  INTERNAL WIRES/REGISTERS/PARAMETERS DECLARATION
-------------------------------------------------------------------------------

-- peripherals to include or exclude from the bus = vlaggen zetten
constant PERIPH_UART0 : boolean := true;
constant PERIPH_UART1 : boolean := true;
constant PERIPH_VGA0 : boolean := true;
constant PERIPH_DAC0 : boolean := false;
constant PERIPH_LCD0 : boolean := false;
constant PERIPH_LCD0_GPIO : boolean := false;
constant PERIPH_ETH0 : boolean := false;

-- clock logic
signal clk_50M_in, CLK0_BUF, CLKFB_IN : STD_LOGIC;
signal dcm_clk_20M, clk_sys : STD_LOGIC;
signal dcm_clk_4M, clk_baud : STD_LOGIC;
signal dcm_locked : STD_LOGIC;
signal reset_pin, reset_n : STD_LOGIC;
signal gsr_tb, gts_tb : STD_LOGIC;

-- openMSP430 buses
signal per_addr  : STD_LOGIC_VECTOR(13 downto 0);     
signal per_din   : STD_LOGIC_VECTOR(15 downto 0);      
signal per_we    : STD_LOGIC_VECTOR( 1 downto 0);      
signal per_dout  : STD_LOGIC_VECTOR(15 downto 0);
signal per_en    : STD_LOGIC;
signal dmem_addr : STD_LOGIC_VECTOR(DMEM_AWIDTH-1 downto 0);    
signal dmem_din  : STD_LOGIC_VECTOR(15 downto 0);     
signal dmem_wen  : STD_LOGIC_VECTOR( 1 downto 0);     
signal dmem_dout : STD_LOGIC_VECTOR(15 downto 0);
signal pmem_addr : STD_LOGIC_VECTOR(PMEM_AWIDTH-1 downto 0);    
signal pmem_din  : STD_LOGIC_VECTOR(15 downto 0);     
signal pmem_wen  : STD_LOGIC_VECTOR( 1 downto 0);     
signal pmem_dout : STD_LOGIC_VECTOR(15 downto 0);
signal irq_acc   : STD_LOGIC_VECTOR(13 downto 0);      
signal irq_bus   : STD_LOGIC_VECTOR(13 downto 0);
signal nmi       : STD_LOGIC;
signal aclk_en, mclk : STD_LOGIC;
signal dbg_freeze, dbg_uart_txd, dbg_uart_rxd : STD_LOGIC;
signal dmem_cen, pmem_cen : STD_LOGIC;
signal puc_rst   : STD_LOGIC;
signal smclk_en  : STD_LOGIC;

-- GPIO
signal p3_din       : STD_LOGIC_VECTOR( 7 downto 0);
signal p3_dout      : STD_LOGIC_VECTOR( 7 downto 0);
signal p3_dout_en   : STD_LOGIC_VECTOR( 7 downto 0);
signal p3_dout_gpio : STD_LOGIC_VECTOR( 7 downto 0);
signal GPIO3_DAT_I  : STD_LOGIC_VECTOR(15 downto 0);

-- VGA pong driver
signal vga_red, vga_green, vga_blue	: STD_LOGIC_VECTOR( 3 downto 0);
signal vga_hs, vga_vs : STD_LOGIC;
signal VGA0_DAT_I	: STD_LOGIC_VECTOR(15 downto 0);

-- UART
signal uart_txd_out, uart_rxd_in : STD_LOGIC;
signal uart_txd_out_m, uart_rxd_in_m : STD_LOGIC;
signal UART0_DAT_I : STD_LOGIC_VECTOR(15 downto 0);
signal UART1_DAT_I : STD_LOGIC_VECTOR(15 downto 0);

-- DAC
signal a_out : STD_LOGIC;
signal DAC0_DAT_I : STD_LOGIC_VECTOR(15 downto 0);

-- LCD
signal p2_dout    : STD_LOGIC_VECTOR( 7 downto 0);
signal LCD0_DAT_I : STD_LOGIC_VECTOR(15 downto 0);

-- Ethernet
signal eth_rst, eth_mdio_i, eth_mdio_o, eth_mdio_t, eth_mdc : STD_LOGIC;
signal eth_txd : STD_LOGIC_VECTOR(4 downto 0);
signal eth_tx_clk, eth_tx_en : STD_LOGIC;
signal ETH0_DAT_I : STD_LOGIC_VECTOR(15 downto 0);

-- WISHBONE MASTER BUS
-- The signals used by the MSP430 are most of time just name alternatives
alias CLK_I     is mclk;
alias RST_I     is puc_rst;
alias MSP_DAT_I is per_dout;
alias MSP_DAT_O is per_din;
alias MSP_ADR_O is per_addr(7 downto 0);
alias MSP_STB_O is per_en;
alias MSP_SEL_O is per_we;
signal MSP_WE_O : STD_LOGIC;

-- COARSE ADDRESS DECODING
signal MSP_COARSE_ADR_O :  STD_LOGIC_VECTOR(6 downto 0);
alias GPIO3_STB_O       is MSP_COARSE_ADR_O(0);
alias UART0_STB_O       is MSP_COARSE_ADR_O(1);
alias VGA0_STB_O        is MSP_COARSE_ADR_O(2);
alias DAC0_STB_O        is MSP_COARSE_ADR_O(3);
alias LCD0_STB_O        is MSP_COARSE_ADR_O(4);
alias UART1_STB_O       is MSP_COARSE_ADR_O(5);
alias ETH0_STB_O        is MSP_COARSE_ADR_O(6);

begin
-------------------------------------------------------------------------------
-- 2)  CLOCK GENERATION
-------------------------------------------------------------------------------

-- Input buffers
ibuf_clk_main: IBUFG port map ( O => clk_50M_in, I => CLK_50MHZ );

-- Digital Clock Manager
-- Generate 20MHz clock from 50MHz on-board oscillator
-- Instance details at http://www.xilinx.com/support/documentation/sw_manuals/xilinx13_3/spartan3_hdl.pdf
dcm_adv_clk_main: DCM 
generic map (
	CLKDV_DIVIDE => 2.5,                   -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
	                                       -- 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
	CLKFX_DIVIDE => 27,                    -- Can be any interger from 1 to 32
	CLKFX_MULTIPLY => 2,                   -- Can be any integer from 1 to 32
	CLKIN_DIVIDE_BY_2 => FALSE,            -- TRUE/FALSE to enable CLKIN divide by two feature
	CLKIN_PERIOD => 20.0,                  -- Specify period of input clock
	CLKOUT_PHASE_SHIFT => "NONE",          -- Specify phase shift of NONE, FIXED or VARIABLE
	CLK_FEEDBACK => "1X",                  -- Specify clock feedback of NONE, 1X or 2X
	DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
	                                       -- an integer from 0 to 15
	DFS_FREQUENCY_MODE => "LOW",           -- HIGH or LOW frequency mode for frequency synthesis
	DLL_FREQUENCY_MODE => "LOW",           -- HIGH or LOW frequency mode for DLL
	DUTY_CYCLE_CORRECTION => TRUE,         -- Duty cycle correction, TRUE or FALSE
	FACTORY_JF => X"C080",                 -- FACTORY JF Values
	PHASE_SHIFT => 0,                      -- Amount of fixed phase shift from -255 to 255
	SIM_MODE => "SAFE",                    -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation
	                                       -- Design Guide" for details
	STARTUP_WAIT => FALSE)                 -- Delay configuration DONE until DCM LOCK, TRUE/FALSE
port map (
	CLK0 => CLK0_BUF,     -- 0 degree DCM CLK ouptput
	CLKDV => dcm_clk_20M, -- Divided DCM CLK out (CLKDV_DIVIDE)
	CLKFX => dcm_clk_4M,  -- DCM CLK synthesis out (M/D)
	LOCKED => dcm_locked, -- DCM LOCK status output
	CLKFB => CLKFB_IN,    -- DCM clock feedback
	CLKIN => clk_50M_in,  -- Clock input (from IBUFG, BUFG or DCM)
	PSCLK => '0',         -- Dynamic phase adjust clock input
	PSEN => '0',          -- Dynamic phase adjust enable input
	PSINCDEC => '0',      -- Dynamic phase adjust increment/decrement
	RST => reset_pin      -- DCM asynchronous reset input
);

CLK0_BUFG_INST : BUFG port map ( I => CLK0_BUF, O => CLKFB_IN );   

-- Clock buffers
buf_sys_clock  : BUFG port map ( I => dcm_clk_20M, O => clk_sys  );
buf_baud_clock : BUFG port map ( I => dcm_clk_4M,  O => clk_baud );

-------------------------------------------------------------------------------
-- 3)  RESET GENERATION & FPGA STARTUP
-------------------------------------------------------------------------------

-- Reset input buffer
ibuf_reset_n: IBUF port map( O => reset_pin, I => BTN_EAST );

-- Release the reset only, if the DCM is locked
reset_n <= (not reset_pin) and dcm_locked;

-- Include the startup device   
xstartup: STARTUP_SPARTAN3 port map (
	CLK => clk_sys, -- Clock input for start-up sequence
	GSR => gsr_tb,  -- Global Set/Reset input (GSR cannot be used for the port name)
	GTS => gts_tb   -- Global 3-state input (GTS cannot be used for the port name)
);

-------------------------------------------------------------------------------
-- 4)  OPENMSP430
-------------------------------------------------------------------------------
openMSP430_0: openMSP430
	port map (
	-- OUTPUTs
    aclk_en      => aclk_en,      -- ACLK enable
    dbg_freeze   => dbg_freeze,   -- Freeze peripherals
    dbg_uart_txd => dbg_uart_txd, -- Debug interface: UART TXD
    dmem_addr    => dmem_addr,    -- Data Memory address
    dmem_cen     => dmem_cen,     -- Data Memory chip enable (low active)
    dmem_din     => dmem_din,     -- Data Memory data input
    dmem_wen     => dmem_wen,     -- Data Memory write enable (low active)
    irq_acc      => irq_acc,      -- Interrupt request accepted (one-hot signal)
    mclk         => mclk,         -- Main system clock
    per_addr     => per_addr,     -- Peripheral address
    per_din      => per_din,      -- Peripheral data input
    per_we       => per_we,       -- Peripheral write enable (high active)
    per_en       => per_en,       -- Peripheral enable (high active)
    pmem_addr    => pmem_addr,    -- Program Memory address
    pmem_cen     => pmem_cen,     -- Program Memory chip enable (low active)
    pmem_din     => pmem_din,     -- Program Memory data input (optional)
    pmem_wen     => pmem_wen,     -- Program Memory write enable (low active) (optional)
    puc_rst      => puc_rst,      -- Main system reset
    smclk_en     => smclk_en,     -- SMCLK enable
	-- INPUTs
	cpu_en       => '1',          -- Enable CPU code execution (asynchronous and non-glitchy)
	dbg_en       => '1',          -- Debug interface enable (asynchronous and non-glitchy)
    dbg_uart_rxd => dbg_uart_rxd, -- Debug interface: UART RXD
    dco_clk      => clk_sys,      -- Fast oscillator (fast clock)
    dmem_dout    => dmem_dout,    -- Data Memory data output
    irq          => irq_bus,      -- Maskable interrupts
    lfxt_clk     => '0',          -- Low frequency oscillator (typ 32kHz)
    nmi          => nmi,          -- Non-maskable interrupt (asynchronous)
    per_dout     => per_dout,     -- Peripheral data output
    pmem_dout    => pmem_dout,    -- Program Memory data output
    reset_n      => reset_n,      -- Reset Pin (low active)
    scan_enable  => '0',          -- ASIC ONLY: Scan enable (active during scan shifting)
    scan_mode    => '0',          -- ASIC ONLY: Scan mode
    wkup         => '0'           -- ASIC ONLY: System Wake-up (asynchronous and non-glitchy)
);

-- Assign interrupts
nmi         <= '0';
irq_bus( 0) <= '0';          -- Vector 13  (0xFFFA)
irq_bus( 1) <= '0';          -- Vector 12  (0xFFF8)
irq_bus( 2) <= '0';          -- Vector 11  (0xFFF6)
irq_bus( 3) <= '0';          -- Vector 10  (0xFFF4) - Watchdog -
irq_bus( 4) <= '0';          -- Vector  9  (0xFFF2)
irq_bus( 5) <= '0';          -- Vector  8  (0xFFF0)
irq_bus( 6) <= '0';          -- Vector  7  (0xFFEE)
irq_bus( 7) <= '0';          -- Vector  6  (0xFFEC)
irq_bus( 8) <= '0';          -- Vector  5  (0xFFEA)
irq_bus( 9) <= '0';          -- Vector  4  (0xFFE8)
irq_bus(10) <= '0';          -- Vector  3  (0xFFE6)
irq_bus(11) <= '0';          -- Vector  2  (0xFFE4)
irq_bus(12) <= '0';          -- Vector  1  (0xFFE2)
irq_bus(13) <= '0';          -- Vector  0  (0xFFE0)

-------------------------------------------------------------------------------
-- 5)  OPENMSP430 PERIPHERALS
-------------------------------------------------------------------------------

-- whisbone master signals
MSP_WE_O  <= MSP_SEL_O(0) OR MSP_SEL_O(1);

-- coarse address decoding
MSP_COARSE_ADR_O(0) <= MSP_STB_O when MSP_ADR_O(7 downto 3) = "00001" else '0';
MSP_COARSE_ADR_O(1) <= MSP_STB_O when MSP_ADR_O(7 downto 3) = "00010" else '0';
MSP_COARSE_ADR_O(2) <= MSP_STB_O when MSP_ADR_O(7 downto 3) = "00011" else '0';
MSP_COARSE_ADR_O(3) <= MSP_STB_O when MSP_ADR_O(7 downto 3) = "00100" else '0';
MSP_COARSE_ADR_O(4) <= MSP_STB_O when MSP_ADR_O(7 downto 4) = "0011"  else '0'; -- double range
MSP_COARSE_ADR_O(5) <= MSP_STB_O when MSP_ADR_O(7 downto 3) = "01000" else '0';
MSP_COARSE_ADR_O(6) <= MSP_STB_O when MSP_ADR_O(7 downto 3) = "01001" else '0';

-- peripherals
vga0 : if (PERIPH_VGA0) generate
msp_vga_0: msp_vga port map (
               -- VGA SIGNALS
	vga_clk_50M => clk_50M_in,
	vga_hsync   => vga_hs,
	vga_vsync   => vga_vs,
	vga_red     => vga_red,
	vga_green   => vga_green,
	vga_blue    => vga_blue,
               -- WISHBONE BUS
    RST_I => RST_I,
    CLK_I => CLK_I,
    ADR_I => MSP_ADR_O(1 downto 0),
    DAT_I => MSP_DAT_O,
    DAT_O => VGA0_DAT_I,
    WE_I  => MSP_WE_O,
    SEL_I => MSP_SEL_O,
    STB_I => VGA0_STB_O
);
end generate;

serial0 : if (PERIPH_UART0) generate
msp_serial_0: msp_serial port map (
                -- UART signals
    CLK_BAUDGEN => clk_baud,
    TXD         => uart_txd_out_m,
    RXD         => uart_rxd_in_m,
                -- WISHBONE BUS
    RST_I       => RST_I,
    CLK_I       => CLK_I,
    ADR_I       => MSP_ADR_O(1 downto 0),
    DAT_I       => MSP_DAT_O, 
    DAT_O       => UART0_DAT_I,
    WE_I        => MSP_WE_O,
    SEL_I       => MSP_SEL_O,
    STB_I       => UART0_STB_O
);
end generate;

serial1 : if (PERIPH_UART1) generate
msp_serial_1: msp_serial port map (
                -- UART signals
    CLK_BAUDGEN => clk_baud,
    TXD         => RS232_DTE_TXD,
    RXD         => RS232_DTE_RXD,
                -- WISHBONE BUS
    RST_I       => RST_I,
    CLK_I       => CLK_I,
    ADR_I       => MSP_ADR_O(1 downto 0),
    DAT_I       => MSP_DAT_O, 
    DAT_O       => UART1_DAT_I,
    WE_I        => MSP_WE_O,
    SEL_I       => MSP_SEL_O,
    STB_I       => UART1_STB_O
);      
end generate;

msp_gpio_3: msp_gpio port map (
    port_in  => p3_din,
    port_out => p3_dout,
    port_dir => p3_dout_en,
    -- WISHBONE BUS
    RST_I => RST_I,
    CLK_I => CLK_I,
    ADR_I => MSP_ADR_O(1 downto 0),
    DAT_I => MSP_DAT_O,
    DAT_O => GPIO3_DAT_I,
    WE_I  => MSP_WE_O,
    SEL_I => MSP_SEL_O,
    STB_I => GPIO3_STB_O
);

dac0 : if (PERIPH_DAC0) generate
msp_dac0: msp_dac port map (
    CLK_50MHZ => clk_50M_in,
    A_OUT     => a_out,
    -- WISHBONE BUS
    RST_I => RST_I,
    CLK_I => CLK_I,
    ADR_I => MSP_ADR_O(1 downto 0),       
    DAT_I => MSP_DAT_O,       
    DAT_O => DAC0_DAT_I,  
    WE_I  => MSP_WE_O,        
    SEL_I => MSP_SEL_O,       
    STB_I => DAC0_STB_O        
);
end generate;

lcd0 : if (PERIPH_LCD0) generate
msp_lcd0: msp_lcd port map (
	lcd_db => LCD_DB, 
	lcd_e  => LCD_E,
	lcd_rs => LCD_RS,
	lcd_rw => LCD_RW,
    -- WISHBONE BUS
    RST_I => RST_I,
    CLK_I => CLK_I,
    ADR_I => MSP_ADR_O(4 downto 0),       
    DAT_I => MSP_DAT_O,       
    DAT_O => LCD0_DAT_I,  
    WE_I  => MSP_WE_O,        
    SEL_I => MSP_SEL_O,       
    STB_I => LCD0_STB_O        
);
end generate;

lcd0_gpio : if (PERIPH_LCD0_GPIO) generate
msp_gpio_2: msp_gpio port map (
    port_in  => "00000000",
    port_out => p2_dout,
    -- WISHBONE BUS
    RST_I => RST_I,
    CLK_I => CLK_I,
    ADR_I => MSP_ADR_O(1 downto 0),
    DAT_I => MSP_DAT_O,
    DAT_O => LCD0_DAT_I,
    WE_I  => MSP_WE_O,
    SEL_I => MSP_SEL_O,
    STB_I => LCD0_STB_O
);
end generate;

eth0 : if (PERIPH_ETH0) generate
msp_eth_0: msp_ethernet port map (
    E_MDC    => eth_mdc,
    E_MDIO_I => eth_mdio_i,
    E_MDIO_O => eth_mdio_o,
    E_MDIO_T => eth_mdio_t,
    E_NRST   => eth_rst,
	E_TXD	 => eth_txd,
	E_TX_CLK => eth_tx_clk,
	E_TX_EN  => eth_tx_en,
    -- WISHBONE BUS
    RST_I => RST_I,
    CLK_I => CLK_I,
    ADR_I => MSP_ADR_O(2 downto 0),
    DAT_I => MSP_DAT_O,
    DAT_O => LCD0_DAT_I,
    WE_I  => MSP_WE_O,
    SEL_I => MSP_SEL_O,
    STB_I => ETH0_STB_O
);
end generate;

-- Combine peripheral data buses
MSP_DAT_I <= VGA0_DAT_I OR UART0_DAT_I OR UART1_DAT_I OR GPIO3_DAT_I OR DAC0_DAT_I OR LCD0_DAT_I OR ETH0_DAT_I;

-------------------------------------------------------------------------------
-- 6)  PROGRAM AND DATA MEMORIES
-------------------------------------------------------------------------------

-- Data Memory
ram_8x512_hi_0: ram_8bit
	generic map ( MEM_AWIDTH => DMEM_AWIDTH )
	port map ( clk => clk_sys, en => dmem_cen, we => dmem_wen(1),
    		   addr => dmem_addr, din => dmem_din(15 downto 8), dout => dmem_dout(15 downto 8) );
ram_8x512_lo_0: ram_8bit
	generic map ( MEM_AWIDTH => DMEM_AWIDTH )
	port map ( clk => clk_sys, en => dmem_cen, we => dmem_wen(0),
    		   addr => dmem_addr, din => dmem_din(7 downto 0), dout => dmem_dout(7 downto 0) );

-- Program Memory
rom_8x2k_hi_0: ram_8bit
	generic map ( MEM_AWIDTH => PMEM_AWIDTH )
	port map ( clk => clk_sys, en => pmem_cen, we => pmem_wen(1),
    		   addr => pmem_addr, din => pmem_din(15 downto 8), dout => pmem_dout(15 downto 8) );
rom_8x2k_lo_0: ram_8bit
	generic map ( MEM_AWIDTH => PMEM_AWIDTH )
	port map ( clk => clk_sys, en => pmem_cen, we => pmem_wen(0),
    		   addr => pmem_addr, din => pmem_din(7 downto 0), dout => pmem_dout(7 downto 0) );


-------------------------------------------------------------------------------
-- 7)  I/O CELLS
-------------------------------------------------------------------------------

-- Slide Switches (Port 1 inputs)
SW3_PIN: IBUF port map ( O => p3_din(3), I => SW3 );
SW2_PIN: IBUF port map ( O => p3_din(2), I => SW2 );
SW1_PIN: IBUF port map ( O => p3_din(1), I => SW1 );
SW0_PIN: IBUF port map ( O => p3_din(0), I => SW0 );

-- LEDs (Port 1 outputs)
p3_dout_gpio <= p3_dout and p3_dout_en;
LED7_PIN: OBUF port map ( I => p3_dout_gpio(7), O => LED7 );
LED6_PIN: OBUF port map ( I => p3_dout_gpio(6), O => LED6 );
LED5_PIN: OBUF port map ( I => p3_dout_gpio(5), O => LED5 );
LED4_PIN: OBUF port map ( I => p3_dout_gpio(4), O => LED4 );
LED3_PIN: OBUF port map ( I => p3_dout_gpio(3), O => LED3 );
LED2_PIN: OBUF port map ( I => p3_dout_gpio(2), O => LED2 );
LED1_PIN: OBUF port map ( I => p3_dout_gpio(1), O => LED1 );
LED0_PIN: OBUF port map ( I => p3_dout_gpio(0), O => LED0 );
   
-- Push Button Switches
BTN_NORTH_PIN: IBUF port map ( O => p3_din(6), I => BTN_NORTH );
BTN_SOUTH_PIN: IBUF port map ( O => p3_din(5), I => BTN_SOUTH );
BTN_WEST_PIN:  IBUF port map ( O => p3_din(4), I => BTN_WEST );

-- Mux the RS-232 port between IO port and the debug interface.
-- The mux is controlled with the SW0 switch
uart_txd_out  <= dbg_uart_txd when p3_din(0) = '1' else uart_txd_out_m;
uart_rxd_in_m <= '1'          when p3_din(0) = '1' else uart_rxd_in;
dbg_uart_rxd  <= uart_rxd_in  when p3_din(0) = '1' else '1';

RS232_DCE_RXD_PIN: IBUF port map ( O => uart_rxd_in,  I => RS232_DCE_RXD );
RS232_DCE_TXD_PIN: OBUF port map ( I => uart_txd_out, O => RS232_DCE_TXD );

-- DAC
DAC_PIN: OBUF port map ( I => a_out, O => DAC_OUT );

-- LCD
LCD_DB0_PIN: OBUF port map ( I => '0',        O => LCD_DB(0) );
LCD_DB1_PIN: OBUF port map ( I => '0',        O => LCD_DB(1) );
LCD_DB2_PIN: OBUF port map ( I => '0',        O => LCD_DB(2) );
LCD_DB3_PIN: OBUF port map ( I => '0',        O => LCD_DB(3) );
LCD_DB4_PIN: OBUF port map ( I => p2_dout(0), O => LCD_DB(4) );
LCD_DB5_PIN: OBUF port map ( I => p2_dout(1), O => LCD_DB(5) );
LCD_DB6_PIN: OBUF port map ( I => p2_dout(2), O => LCD_DB(6) );
LCD_DB7_PIN: OBUF port map ( I => p2_dout(3), O => LCD_DB(7) );
LCD_E_PIN:   OBUF port map ( I => p2_dout(4), O => LCD_E     );
LCD_RS_PIN:  OBUF port map ( I => p2_dout(5), O => LCD_RS    );
LCD_RW_PIN:  OBUF port map ( I => p2_dout(6), O => LCD_RW    );

-- VGA
VGA_R0_PIN:    OBUF port map (I => vga_red(0),   O => VGA_R(0)  );
VGA_R1_PIN:    OBUF port map (I => vga_red(1),   O => VGA_R(1)  );
VGA_R2_PIN:    OBUF port map (I => vga_red(2),   O => VGA_R(2)  );
VGA_R3_PIN:    OBUF port map (I => vga_red(3),   O => VGA_R(3)  );
VGA_G0_PIN:    OBUF port map (I => vga_green(0), O => VGA_G(0)  );
VGA_G1_PIN:    OBUF port map (I => vga_green(1), O => VGA_G(1)  );
VGA_G2_PIN:    OBUF port map (I => vga_green(2), O => VGA_G(2)  );
VGA_G3_PIN:    OBUF port map (I => vga_green(3), O => VGA_G(3)  );
VGA_B0_PIN:    OBUF port map (I => vga_blue(0),  O => VGA_B(0)  );
VGA_B1_PIN:    OBUF port map (I => vga_blue(1),  O => VGA_B(1)  );
VGA_B2_PIN:    OBUF port map (I => vga_blue(2),  O => VGA_B(2)  );
VGA_B3_PIN:    OBUF port map (I => vga_blue(3),  O => VGA_B(3)  );
VGA_HSYNC_PIN: OBUF port map (I => vga_hs,       O => VGA_HSYNC );
VGA_VSYNC_PIN: OBUF port map (I => vga_vs,       O => VGA_VSYNC );

-- Ethernet
E_NRST_PIN:    OBUF  port map (I => eth_rst,      O => E_NRST   );
E_MDC_PIN:     OBUF  port map (I => eth_mdc,      O => E_MDC    );
E_MDIO_PIN:    IOBUF port map (I => eth_mdio_o,   O => eth_mdio_i,   T => eth_mdio_t,   IO => E_MDIO);
E_TX_EN_PIN:   OBUF  port map (I => eth_tx_en,    O => E_TX_EN  );
E_TX_CLK_PIN:  BUFG  port map (O => eth_tx_clk,   I => E_TX_CLK );
E_TXD0_PIN:    OBUF  port map (I => eth_txd(0),   O => E_TXD(0) );
E_TXD1_PIN:    OBUF  port map (I => eth_txd(1),   O => E_TXD(1) );
E_TXD2_PIN:    OBUF  port map (I => eth_txd(2),   O => E_TXD(2) );
E_TXD3_PIN:    OBUF  port map (I => eth_txd(3),   O => E_TXD(3) );
E_TXD4_PIN:    OBUF  port map (I => eth_txd(4),   O => E_TXD(4) );

end Behavioral;
