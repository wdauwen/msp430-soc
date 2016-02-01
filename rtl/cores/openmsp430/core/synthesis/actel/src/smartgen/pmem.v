`timescale 1 ns/100 ps
// Version: 8.5 8.5.0.34


module pmem(WD,RD,WEN,REN,WADDR,RADDR,RWCLK,RESET);
input [7:0] WD;
output [7:0] RD;
input  WEN, REN;
input [11:0] WADDR, RADDR;
input RWCLK, RESET;

    wire VCC, GND;
    
    VCC VCC_1_net(.Y(VCC));
    GND GND_1_net(.Y(GND));
    RAM4K9 pmem_R0C3(.ADDRA11(WADDR[11]), .ADDRA10(WADDR[10]), 
        .ADDRA9(WADDR[9]), .ADDRA8(WADDR[8]), .ADDRA7(WADDR[7]), 
        .ADDRA6(WADDR[6]), .ADDRA5(WADDR[5]), .ADDRA4(WADDR[4]), 
        .ADDRA3(WADDR[3]), .ADDRA2(WADDR[2]), .ADDRA1(WADDR[1]), 
        .ADDRA0(WADDR[0]), .ADDRB11(RADDR[11]), .ADDRB10(
        RADDR[10]), .ADDRB9(RADDR[9]), .ADDRB8(RADDR[8]), .ADDRB7(
        RADDR[7]), .ADDRB6(RADDR[6]), .ADDRB5(RADDR[5]), .ADDRB4(
        RADDR[4]), .ADDRB3(RADDR[3]), .ADDRB2(RADDR[2]), .ADDRB1(
        RADDR[1]), .ADDRB0(RADDR[0]), .DINA8(GND), .DINA7(GND), 
        .DINA6(GND), .DINA5(GND), .DINA4(GND), .DINA3(GND), 
        .DINA2(GND), .DINA1(GND), .DINA0(WD[3]), .DINB8(GND), 
        .DINB7(GND), .DINB6(GND), .DINB5(GND), .DINB4(GND), 
        .DINB3(GND), .DINB2(GND), .DINB1(GND), .DINB0(GND), 
        .WIDTHA0(GND), .WIDTHA1(GND), .WIDTHB0(GND), .WIDTHB1(GND)
        , .PIPEA(GND), .PIPEB(GND), .WMODEA(GND), .WMODEB(GND), 
        .BLKA(WEN), .BLKB(REN), .WENA(GND), .WENB(VCC), .CLKA(
        RWCLK), .CLKB(RWCLK), .RESET(RESET), .DOUTA8(), .DOUTA7(), 
        .DOUTA6(), .DOUTA5(), .DOUTA4(), .DOUTA3(), .DOUTA2(), 
        .DOUTA1(), .DOUTA0(), .DOUTB8(), .DOUTB7(), .DOUTB6(), 
        .DOUTB5(), .DOUTB4(), .DOUTB3(), .DOUTB2(), .DOUTB1(), 
        .DOUTB0(RD[3]));
    RAM4K9 pmem_R0C4(.ADDRA11(WADDR[11]), .ADDRA10(WADDR[10]), 
        .ADDRA9(WADDR[9]), .ADDRA8(WADDR[8]), .ADDRA7(WADDR[7]), 
        .ADDRA6(WADDR[6]), .ADDRA5(WADDR[5]), .ADDRA4(WADDR[4]), 
        .ADDRA3(WADDR[3]), .ADDRA2(WADDR[2]), .ADDRA1(WADDR[1]), 
        .ADDRA0(WADDR[0]), .ADDRB11(RADDR[11]), .ADDRB10(
        RADDR[10]), .ADDRB9(RADDR[9]), .ADDRB8(RADDR[8]), .ADDRB7(
        RADDR[7]), .ADDRB6(RADDR[6]), .ADDRB5(RADDR[5]), .ADDRB4(
        RADDR[4]), .ADDRB3(RADDR[3]), .ADDRB2(RADDR[2]), .ADDRB1(
        RADDR[1]), .ADDRB0(RADDR[0]), .DINA8(GND), .DINA7(GND), 
        .DINA6(GND), .DINA5(GND), .DINA4(GND), .DINA3(GND), 
        .DINA2(GND), .DINA1(GND), .DINA0(WD[4]), .DINB8(GND), 
        .DINB7(GND), .DINB6(GND), .DINB5(GND), .DINB4(GND), 
        .DINB3(GND), .DINB2(GND), .DINB1(GND), .DINB0(GND), 
        .WIDTHA0(GND), .WIDTHA1(GND), .WIDTHB0(GND), .WIDTHB1(GND)
        , .PIPEA(GND), .PIPEB(GND), .WMODEA(GND), .WMODEB(GND), 
        .BLKA(WEN), .BLKB(REN), .WENA(GND), .WENB(VCC), .CLKA(
        RWCLK), .CLKB(RWCLK), .RESET(RESET), .DOUTA8(), .DOUTA7(), 
        .DOUTA6(), .DOUTA5(), .DOUTA4(), .DOUTA3(), .DOUTA2(), 
        .DOUTA1(), .DOUTA0(), .DOUTB8(), .DOUTB7(), .DOUTB6(), 
        .DOUTB5(), .DOUTB4(), .DOUTB3(), .DOUTB2(), .DOUTB1(), 
        .DOUTB0(RD[4]));
    RAM4K9 pmem_R0C6(.ADDRA11(WADDR[11]), .ADDRA10(WADDR[10]), 
        .ADDRA9(WADDR[9]), .ADDRA8(WADDR[8]), .ADDRA7(WADDR[7]), 
        .ADDRA6(WADDR[6]), .ADDRA5(WADDR[5]), .ADDRA4(WADDR[4]), 
        .ADDRA3(WADDR[3]), .ADDRA2(WADDR[2]), .ADDRA1(WADDR[1]), 
        .ADDRA0(WADDR[0]), .ADDRB11(RADDR[11]), .ADDRB10(
        RADDR[10]), .ADDRB9(RADDR[9]), .ADDRB8(RADDR[8]), .ADDRB7(
        RADDR[7]), .ADDRB6(RADDR[6]), .ADDRB5(RADDR[5]), .ADDRB4(
        RADDR[4]), .ADDRB3(RADDR[3]), .ADDRB2(RADDR[2]), .ADDRB1(
        RADDR[1]), .ADDRB0(RADDR[0]), .DINA8(GND), .DINA7(GND), 
        .DINA6(GND), .DINA5(GND), .DINA4(GND), .DINA3(GND), 
        .DINA2(GND), .DINA1(GND), .DINA0(WD[6]), .DINB8(GND), 
        .DINB7(GND), .DINB6(GND), .DINB5(GND), .DINB4(GND), 
        .DINB3(GND), .DINB2(GND), .DINB1(GND), .DINB0(GND), 
        .WIDTHA0(GND), .WIDTHA1(GND), .WIDTHB0(GND), .WIDTHB1(GND)
        , .PIPEA(GND), .PIPEB(GND), .WMODEA(GND), .WMODEB(GND), 
        .BLKA(WEN), .BLKB(REN), .WENA(GND), .WENB(VCC), .CLKA(
        RWCLK), .CLKB(RWCLK), .RESET(RESET), .DOUTA8(), .DOUTA7(), 
        .DOUTA6(), .DOUTA5(), .DOUTA4(), .DOUTA3(), .DOUTA2(), 
        .DOUTA1(), .DOUTA0(), .DOUTB8(), .DOUTB7(), .DOUTB6(), 
        .DOUTB5(), .DOUTB4(), .DOUTB3(), .DOUTB2(), .DOUTB1(), 
        .DOUTB0(RD[6]));
    RAM4K9 pmem_R0C5(.ADDRA11(WADDR[11]), .ADDRA10(WADDR[10]), 
        .ADDRA9(WADDR[9]), .ADDRA8(WADDR[8]), .ADDRA7(WADDR[7]), 
        .ADDRA6(WADDR[6]), .ADDRA5(WADDR[5]), .ADDRA4(WADDR[4]), 
        .ADDRA3(WADDR[3]), .ADDRA2(WADDR[2]), .ADDRA1(WADDR[1]), 
        .ADDRA0(WADDR[0]), .ADDRB11(RADDR[11]), .ADDRB10(
        RADDR[10]), .ADDRB9(RADDR[9]), .ADDRB8(RADDR[8]), .ADDRB7(
        RADDR[7]), .ADDRB6(RADDR[6]), .ADDRB5(RADDR[5]), .ADDRB4(
        RADDR[4]), .ADDRB3(RADDR[3]), .ADDRB2(RADDR[2]), .ADDRB1(
        RADDR[1]), .ADDRB0(RADDR[0]), .DINA8(GND), .DINA7(GND), 
        .DINA6(GND), .DINA5(GND), .DINA4(GND), .DINA3(GND), 
        .DINA2(GND), .DINA1(GND), .DINA0(WD[5]), .DINB8(GND), 
        .DINB7(GND), .DINB6(GND), .DINB5(GND), .DINB4(GND), 
        .DINB3(GND), .DINB2(GND), .DINB1(GND), .DINB0(GND), 
        .WIDTHA0(GND), .WIDTHA1(GND), .WIDTHB0(GND), .WIDTHB1(GND)
        , .PIPEA(GND), .PIPEB(GND), .WMODEA(GND), .WMODEB(GND), 
        .BLKA(WEN), .BLKB(REN), .WENA(GND), .WENB(VCC), .CLKA(
        RWCLK), .CLKB(RWCLK), .RESET(RESET), .DOUTA8(), .DOUTA7(), 
        .DOUTA6(), .DOUTA5(), .DOUTA4(), .DOUTA3(), .DOUTA2(), 
        .DOUTA1(), .DOUTA0(), .DOUTB8(), .DOUTB7(), .DOUTB6(), 
        .DOUTB5(), .DOUTB4(), .DOUTB3(), .DOUTB2(), .DOUTB1(), 
        .DOUTB0(RD[5]));
    RAM4K9 pmem_R0C0(.ADDRA11(WADDR[11]), .ADDRA10(WADDR[10]), 
        .ADDRA9(WADDR[9]), .ADDRA8(WADDR[8]), .ADDRA7(WADDR[7]), 
        .ADDRA6(WADDR[6]), .ADDRA5(WADDR[5]), .ADDRA4(WADDR[4]), 
        .ADDRA3(WADDR[3]), .ADDRA2(WADDR[2]), .ADDRA1(WADDR[1]), 
        .ADDRA0(WADDR[0]), .ADDRB11(RADDR[11]), .ADDRB10(
        RADDR[10]), .ADDRB9(RADDR[9]), .ADDRB8(RADDR[8]), .ADDRB7(
        RADDR[7]), .ADDRB6(RADDR[6]), .ADDRB5(RADDR[5]), .ADDRB4(
        RADDR[4]), .ADDRB3(RADDR[3]), .ADDRB2(RADDR[2]), .ADDRB1(
        RADDR[1]), .ADDRB0(RADDR[0]), .DINA8(GND), .DINA7(GND), 
        .DINA6(GND), .DINA5(GND), .DINA4(GND), .DINA3(GND), 
        .DINA2(GND), .DINA1(GND), .DINA0(WD[0]), .DINB8(GND), 
        .DINB7(GND), .DINB6(GND), .DINB5(GND), .DINB4(GND), 
        .DINB3(GND), .DINB2(GND), .DINB1(GND), .DINB0(GND), 
        .WIDTHA0(GND), .WIDTHA1(GND), .WIDTHB0(GND), .WIDTHB1(GND)
        , .PIPEA(GND), .PIPEB(GND), .WMODEA(GND), .WMODEB(GND), 
        .BLKA(WEN), .BLKB(REN), .WENA(GND), .WENB(VCC), .CLKA(
        RWCLK), .CLKB(RWCLK), .RESET(RESET), .DOUTA8(), .DOUTA7(), 
        .DOUTA6(), .DOUTA5(), .DOUTA4(), .DOUTA3(), .DOUTA2(), 
        .DOUTA1(), .DOUTA0(), .DOUTB8(), .DOUTB7(), .DOUTB6(), 
        .DOUTB5(), .DOUTB4(), .DOUTB3(), .DOUTB2(), .DOUTB1(), 
        .DOUTB0(RD[0]));
    RAM4K9 pmem_R0C2(.ADDRA11(WADDR[11]), .ADDRA10(WADDR[10]), 
        .ADDRA9(WADDR[9]), .ADDRA8(WADDR[8]), .ADDRA7(WADDR[7]), 
        .ADDRA6(WADDR[6]), .ADDRA5(WADDR[5]), .ADDRA4(WADDR[4]), 
        .ADDRA3(WADDR[3]), .ADDRA2(WADDR[2]), .ADDRA1(WADDR[1]), 
        .ADDRA0(WADDR[0]), .ADDRB11(RADDR[11]), .ADDRB10(
        RADDR[10]), .ADDRB9(RADDR[9]), .ADDRB8(RADDR[8]), .ADDRB7(
        RADDR[7]), .ADDRB6(RADDR[6]), .ADDRB5(RADDR[5]), .ADDRB4(
        RADDR[4]), .ADDRB3(RADDR[3]), .ADDRB2(RADDR[2]), .ADDRB1(
        RADDR[1]), .ADDRB0(RADDR[0]), .DINA8(GND), .DINA7(GND), 
        .DINA6(GND), .DINA5(GND), .DINA4(GND), .DINA3(GND), 
        .DINA2(GND), .DINA1(GND), .DINA0(WD[2]), .DINB8(GND), 
        .DINB7(GND), .DINB6(GND), .DINB5(GND), .DINB4(GND), 
        .DINB3(GND), .DINB2(GND), .DINB1(GND), .DINB0(GND), 
        .WIDTHA0(GND), .WIDTHA1(GND), .WIDTHB0(GND), .WIDTHB1(GND)
        , .PIPEA(GND), .PIPEB(GND), .WMODEA(GND), .WMODEB(GND), 
        .BLKA(WEN), .BLKB(REN), .WENA(GND), .WENB(VCC), .CLKA(
        RWCLK), .CLKB(RWCLK), .RESET(RESET), .DOUTA8(), .DOUTA7(), 
        .DOUTA6(), .DOUTA5(), .DOUTA4(), .DOUTA3(), .DOUTA2(), 
        .DOUTA1(), .DOUTA0(), .DOUTB8(), .DOUTB7(), .DOUTB6(), 
        .DOUTB5(), .DOUTB4(), .DOUTB3(), .DOUTB2(), .DOUTB1(), 
        .DOUTB0(RD[2]));
    RAM4K9 pmem_R0C7(.ADDRA11(WADDR[11]), .ADDRA10(WADDR[10]), 
        .ADDRA9(WADDR[9]), .ADDRA8(WADDR[8]), .ADDRA7(WADDR[7]), 
        .ADDRA6(WADDR[6]), .ADDRA5(WADDR[5]), .ADDRA4(WADDR[4]), 
        .ADDRA3(WADDR[3]), .ADDRA2(WADDR[2]), .ADDRA1(WADDR[1]), 
        .ADDRA0(WADDR[0]), .ADDRB11(RADDR[11]), .ADDRB10(
        RADDR[10]), .ADDRB9(RADDR[9]), .ADDRB8(RADDR[8]), .ADDRB7(
        RADDR[7]), .ADDRB6(RADDR[6]), .ADDRB5(RADDR[5]), .ADDRB4(
        RADDR[4]), .ADDRB3(RADDR[3]), .ADDRB2(RADDR[2]), .ADDRB1(
        RADDR[1]), .ADDRB0(RADDR[0]), .DINA8(GND), .DINA7(GND), 
        .DINA6(GND), .DINA5(GND), .DINA4(GND), .DINA3(GND), 
        .DINA2(GND), .DINA1(GND), .DINA0(WD[7]), .DINB8(GND), 
        .DINB7(GND), .DINB6(GND), .DINB5(GND), .DINB4(GND), 
        .DINB3(GND), .DINB2(GND), .DINB1(GND), .DINB0(GND), 
        .WIDTHA0(GND), .WIDTHA1(GND), .WIDTHB0(GND), .WIDTHB1(GND)
        , .PIPEA(GND), .PIPEB(GND), .WMODEA(GND), .WMODEB(GND), 
        .BLKA(WEN), .BLKB(REN), .WENA(GND), .WENB(VCC), .CLKA(
        RWCLK), .CLKB(RWCLK), .RESET(RESET), .DOUTA8(), .DOUTA7(), 
        .DOUTA6(), .DOUTA5(), .DOUTA4(), .DOUTA3(), .DOUTA2(), 
        .DOUTA1(), .DOUTA0(), .DOUTB8(), .DOUTB7(), .DOUTB6(), 
        .DOUTB5(), .DOUTB4(), .DOUTB3(), .DOUTB2(), .DOUTB1(), 
        .DOUTB0(RD[7]));
    RAM4K9 pmem_R0C1(.ADDRA11(WADDR[11]), .ADDRA10(WADDR[10]), 
        .ADDRA9(WADDR[9]), .ADDRA8(WADDR[8]), .ADDRA7(WADDR[7]), 
        .ADDRA6(WADDR[6]), .ADDRA5(WADDR[5]), .ADDRA4(WADDR[4]), 
        .ADDRA3(WADDR[3]), .ADDRA2(WADDR[2]), .ADDRA1(WADDR[1]), 
        .ADDRA0(WADDR[0]), .ADDRB11(RADDR[11]), .ADDRB10(
        RADDR[10]), .ADDRB9(RADDR[9]), .ADDRB8(RADDR[8]), .ADDRB7(
        RADDR[7]), .ADDRB6(RADDR[6]), .ADDRB5(RADDR[5]), .ADDRB4(
        RADDR[4]), .ADDRB3(RADDR[3]), .ADDRB2(RADDR[2]), .ADDRB1(
        RADDR[1]), .ADDRB0(RADDR[0]), .DINA8(GND), .DINA7(GND), 
        .DINA6(GND), .DINA5(GND), .DINA4(GND), .DINA3(GND), 
        .DINA2(GND), .DINA1(GND), .DINA0(WD[1]), .DINB8(GND), 
        .DINB7(GND), .DINB6(GND), .DINB5(GND), .DINB4(GND), 
        .DINB3(GND), .DINB2(GND), .DINB1(GND), .DINB0(GND), 
        .WIDTHA0(GND), .WIDTHA1(GND), .WIDTHB0(GND), .WIDTHB1(GND)
        , .PIPEA(GND), .PIPEB(GND), .WMODEA(GND), .WMODEB(GND), 
        .BLKA(WEN), .BLKB(REN), .WENA(GND), .WENB(VCC), .CLKA(
        RWCLK), .CLKB(RWCLK), .RESET(RESET), .DOUTA8(), .DOUTA7(), 
        .DOUTA6(), .DOUTA5(), .DOUTA4(), .DOUTA3(), .DOUTA2(), 
        .DOUTA1(), .DOUTA0(), .DOUTB8(), .DOUTB7(), .DOUTB6(), 
        .DOUTB5(), .DOUTB4(), .DOUTB3(), .DOUTB2(), .DOUTB1(), 
        .DOUTB0(RD[1]));
    
endmodule