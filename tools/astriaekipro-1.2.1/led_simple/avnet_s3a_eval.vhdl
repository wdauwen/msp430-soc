package AvnetS3AEval is
   constant BRD_CLK_I : string:="C10";  -- 16 MHz
   constant BRD_CLK2_I: string:="N9";   -- 12 MHz
   constant BRD_CLK3_I: string:="T7";   -- 32 kHz
   -- LEDs
   constant BRD_LED1_O: string:="D14";
   constant BRD_LED2_O: string:="C16";
   constant BRD_LED3_O: string:="C15";
   constant BRD_LED4_O: string:="B15";
   -- Push Buttons
   constant BRD_PB1_I : string:="K3";  -- Capsense A
   constant BRD_PB2_I : string:="H5";  -- Capsense B
   constant BRD_PB3_I : string:="L3";  -- Capsense C
   -- RS-232
   constant BRD_RX_I  : string:="A3";
   constant BRD_TX_O  : string:="B3";
end package AvnetS3AEval;

