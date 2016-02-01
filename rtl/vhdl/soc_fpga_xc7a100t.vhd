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
    	CLK_100MHZ : in  STD_LOGIC;
		-- Push Button Switches
	    PUSH_A    : in  STD_LOGIC;
	    PUSH_B    : in  STD_LOGIC;
	    PUSH_C    : in  STD_LOGIC;
	    RESET     : in  STD_LOGIC;
		-- LEDs
	    LED       : out STD_LOGIC_VECTOR(3 downto 0);
		-- RS-232 Port
    	RS232_RXD : in  STD_LOGIC;
    	RS232_TXD : out STD_LOGIC;
    	RS232_LOG_RXD : in  STD_LOGIC;
    	RS232_LOG_TXD : out STD_LOGIC;
    	RS232_DBG_RXD : in  STD_LOGIC;
    	RS232_DBG_TXD : out STD_LOGIC;
    	-- DAC Port
    	DAC_OUT   : out STD_LOGIC
    	 );
end openMSP430_fpga;
	
architecture Behavioral of openMSP430_fpga is	

-------------------------------------------------------------------------------
-- 1)  INTERNAL WIRES/REGISTERS/PARAMETERS DECLARATION
-------------------------------------------------------------------------------

-- peripherals to include or exclude from the bus
constant PERIPH_UART0 : boolean := false;
constant PERIPH_UART1 : boolean := false;
constant PERIPH_DAC0 : boolean := false;

-- clock logic
signal clk_100M_in, CLK0_BUF, CLKFB_IN : STD_LOGIC;
signal dcm_clk_20M, clk_sys : STD_LOGIC;
signal dcm_clk_4M, clk_baud : STD_LOGIC;
signal dcm_locked : STD_LOGIC;
signal reset_pin, reset_n : STD_LOGIC;

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

-- UART
signal uart_txd_out, uart_rxd_in : STD_LOGIC;
signal UART0_DAT_I : STD_LOGIC_VECTOR(15 downto 0);
signal uart_log_txd_out, uart_log_rxd_in : STD_LOGIC;
signal UART1_DAT_I : STD_LOGIC_VECTOR(15 downto 0);

-- DAC
signal a_out : STD_LOGIC;
signal DAC0_DAT_I : STD_LOGIC_VECTOR(15 downto 0);

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
signal MSP_COARSE_ADR_O :  STD_LOGIC_VECTOR(5 downto 0);
alias GPIO3_STB_O       is MSP_COARSE_ADR_O(0);
alias UART0_STB_O       is MSP_COARSE_ADR_O(1);
alias DAC0_STB_O        is MSP_COARSE_ADR_O(3);
alias UART1_STB_O       is MSP_COARSE_ADR_O(5);

begin
-------------------------------------------------------------------------------
-- 2)  CLOCK GENERATION
-------------------------------------------------------------------------------

-- Input buffers
ibuf_clk_main: IBUFG port map ( O => clk_100M_in,  I => CLK_100MHZ );

-- Digital Clock Manager
-- Generate 20MHz clock from 16MHz on-board oscillator

-- PLLE2_BASE: Base Phase Locked Loop (PLL)
-- 7 Series
-- Xilinx HDL Libraries Guide, version 14.2
PLLE2_BASE_inst : PLLE2_BASE
generic map (
	BANDWIDTH => "OPTIMIZED", 	-- OPTIMIZED, HIGH, LOW
	CLKFBOUT_MULT => 2, 		-- Multiply value for all CLKOUT, (2-64)
	CLKFBOUT_PHASE => 0.0, 		-- Phase offset in degrees of CLKFB, (-360.000-360.000).
	CLKIN1_PERIOD => 10.0, 		-- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
	-- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
	CLKOUT0_DIVIDE => 5,	-- 100 / 2 / 5 * 2 = 20MHz
	CLKOUT1_DIVIDE => 1,
	CLKOUT2_DIVIDE => 1,
	CLKOUT3_DIVIDE => 1,
	CLKOUT4_DIVIDE => 1,
	CLKOUT5_DIVIDE => 1,
	-- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
	CLKOUT0_DUTY_CYCLE => 0.5,
	CLKOUT1_DUTY_CYCLE => 0.5,
	CLKOUT2_DUTY_CYCLE => 0.5,
	CLKOUT3_DUTY_CYCLE => 0.5,
	CLKOUT4_DUTY_CYCLE => 0.5,
	CLKOUT5_DUTY_CYCLE => 0.5,
	-- CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
	CLKOUT0_PHASE => 0.0,
	CLKOUT1_PHASE => 0.0,
	CLKOUT2_PHASE => 0.0,
	CLKOUT3_PHASE => 0.0,
	CLKOUT4_PHASE => 0.0,
	CLKOUT5_PHASE => 0.0,
	DIVCLK_DIVIDE => 2, 		-- Master division value, (1-56)
	REF_JITTER1 => 0.0, 		-- Reference input jitter in UI, (0.000-0.999).
	STARTUP_WAIT => "FALSE" 	-- Delay DONE until PLL Locks, ("TRUE"/"FALSE")
)
port map (
	-- Clock Outputs: 1-bit (each) output: User configurable clock outputs
	CLKOUT0 => CLKOUT0,
	CLKOUT1 => CLKOUT1,
	CLKOUT2 => CLKOUT2,
	CLKOUT3 => CLKOUT3,
	CLKOUT4 => CLKOUT4,
	CLKOUT5 => CLKOUT5,
	-- Feedback Clocks: 1-bit (each) output: Clock feedback ports
	CLKFBOUT => CLKFBOUT, -- 1-bit output: Feedback clock
	-- Status Port: 1-bit (each) output: PLL status ports
	LOCKED => LOCKED, -- 1-bit output: LOCK
	-- Clock Input: 1-bit (each) input: Clock input
	CLKIN1 => CLKIN1, -- 1-bit input: Input clock
	-- Control Ports: 1-bit (each) input: PLL control ports
	PWRDWN => PWRDWN, -- 1-bit input: Power-down
	RST => RST, -- 1-bit input: Reset
	-- Feedback Clocks: 1-bit (each) input: Clock feedback ports
	CLKFBIN => CLKFBIN -- 1-bit input: Feedback clock
);
-- Instance details at http://www.xilinx.com/support/documentation/sw_manuals/xilinx13_3/spartan3_hdl.pdf
dcm_adv_clk_main: DCM 
generic map (
	CLKDV_DIVIDE => 4.5,                   -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
	                                       -- 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
	CLKFX_DIVIDE => 5,                     -- Can be any interger from 1 to 32
	CLKFX_MULTIPLY => 1,                   -- Can be any integer from 1 to 32
	CLKIN_DIVIDE_BY_2 => FALSE,            -- TRUE/FALSE to enable CLKIN divide by two feature
	CLKIN_PERIOD => 62.5,                  -- Specify period of input clock
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
	CLKDV => dcm_clk_4M,  -- Divided DCM CLK out (CLKDV_DIVIDE)
	CLKFX => dcm_clk_20M, -- DCM CLK synthesis out (M/D)
	LOCKED => dcm_locked, -- DCM LOCK status output
	CLKFB => CLKFB_IN,    -- DCM clock feedback
	CLKIN => clk_100M_in,  -- Clock input (from IBUFG, BUFG or DCM)
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
ibuf_reset_n: IBUF port map( O => reset_pin, I => RESET );

-- Release the reset only, if the DCM is locked
reset_n <= (not reset_pin) and dcm_locked;

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

serial0 : if (PERIPH_UART0) generate
msp_serial_0: msp_serial port map (
                -- UART signals
    CLK_BAUDGEN => clk_baud,
    TXD         => uart_txd_out,
    RXD         => uart_rxd_in,
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
    TXD         => uart_log_txd_out,
    RXD         => uart_log_rxd_in,
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
    CLK_50MHZ => clk_100M_in,
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

-- Combine peripheral data buses
MSP_DAT_I <= UART0_DAT_I OR
             UART1_DAT_I OR 
             GPIO3_DAT_I OR 
             DAC0_DAT_I;

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

-- LEDs (Port 1 outputs)
p3_dout_gpio <= p3_dout and p3_dout_en;
LED3_PIN: OBUF port map ( I => p3_dout_gpio(3), O => LED(3) );
LED2_PIN: OBUF port map ( I => p3_dout_gpio(2), O => LED(2) );
LED1_PIN: OBUF port map ( I => p3_dout_gpio(1), O => LED(1) );
LED0_PIN: OBUF port map ( I => p3_dout_gpio(0), O => LED(0) );
   
-- Push Button Switches
PUSH_A_PIN: IBUF port map ( O => p3_din(4), I => PUSH_A );
PUSH_B_PIN: IBUF port map ( O => p3_din(5), I => PUSH_B );
PUSH_C_PIN: IBUF port map ( O => p3_din(6), I => PUSH_C );

-- RS232 port
RS232_RXD_PIN: IBUF port map ( O => uart_rxd_in,  I => RS232_RXD );
RS232_TXD_PIN: OBUF port map ( I => uart_txd_out, O => RS232_TXD );

RS232_LOG_RXD_PIN: IBUF port map ( O => uart_log_rxd_in,  I => RS232_LOG_RXD );
RS232_LOG_TXD_PIN: OBUF port map ( I => uart_log_txd_out, O => RS232_LOG_TXD );

dbg_uart_rxd <= '1';
--RS232_DBG_RXD_PIN: IBUF port map ( O => dbg_uart_rxd,  I => '1' );
RS232_DBG_TXD_PIN: OBUF port map ( I => dbg_uart_txd, O => RS232_DBG_TXD );

-- DAC
DAC_PIN: OBUF port map ( I => a_out, O => DAC_OUT );

end Behavioral;
