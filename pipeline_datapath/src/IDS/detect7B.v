////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 10.1.03
//  \   \         Application : sch2verilog
//  /   /         Filename : detect7B.vf
// /___/   /\     Timestamp : 01/28/2026 18:45:47
// \   \  /  \ 
//  \___\/\___\ 
//
//Command: C:\Xilinx\10.1\ISE\bin\nt\unwrapped\sch2verilog.exe -intstyle ise -family virtex2p -w "C:/Documents and Settings/student/Desktop/EE533/Lab3/detect7B.sch" detect7B.vf
//Design Name: detect7B
//Device: virtex2p
//Purpose:
//    This verilog netlist is translated from an ECS schematic.It can be 
//    synthesized and simulated, but it should not be modified. 
//
`timescale 1ns / 1ps

module detect7B(ce, 
                clk, 
                hwregA, 
                match_en, 
                mrst, 
                pipe1, 
                match, 
                pipe0);

    input ce;
    input clk;
    input [63:0] hwregA;
    input match_en;
    input mrst;
    input [71:0] pipe1;
   output match;
   output [71:0] pipe0;
   
   wire XLXN_11;
   wire XLXN_15;
   wire XLXN_21;
   wire [111:0] XLXN_25;
   wire match_DUMMY;
   wire [71:0] pipe0_DUMMY;
   
   assign match = match_DUMMY;
   assign pipe0[71:0] = pipe0_DUMMY[71:0];
   reg9B XLXI_1 (.ce(ce), 
                 .clk(clk), 
                 .clr(XLXN_15), 
                 .d(pipe1[71:0]), 
                 .q(pipe0_DUMMY[71:0]));
   wordmatch XLXI_4 (.datacomp(hwregA[55:0]), 
                     .datain(XLXN_25[111:0]), 
                     .wildcard(hwregA[62:56]), 
                     .match(XLXN_11));
   FD XLXI_6 (.C(clk), 
              .D(mrst), 
              .Q(XLXN_15));
   defparam XLXI_6.INIT = 1'b0;
   AND3B1 XLXI_7 (.I0(match_DUMMY), 
                  .I1(match_en), 
                  .I2(XLXN_11), 
                  .O(XLXN_21));
   FDCE XLXI_8 (.C(clk), 
                .CE(XLXN_21), 
                .CLR(XLXN_15), 
                .D(XLXN_21), 
                .Q(match_DUMMY));
   defparam XLXI_8.INIT = 1'b0;
   busmerge XLXI_9 (.da(pipe0_DUMMY[47:0]), 
                    .db(pipe1[63:0]), 
                    .q(XLXN_25[111:0]));
endmodule
