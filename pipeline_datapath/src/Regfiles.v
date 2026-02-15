`timescale 1ns / 1ps

// ==========================================================
// 64-bit DFF with enable
// ==========================================================
module DFF_64_en(
    input        en,
    input        rst_n,
    input [63:0] data_in,
    input        CLK,
    output reg [63:0] data_out
);

    always @(posedge CLK or negedge rst_n) begin
        if (!rst_n)
            data_out <= 64'b0;
        else if (en)
            data_out <= data_in;
    end

endmodule


// ==========================================================
// 16 × 64-bit Register File
// 2 read ports, 1 write port
// ==========================================================
module Regfiles(
    input  [3:0]  r0addr,
    input  [3:0]  r1addr,
    input         wena,
    input         CLK,
    input         rst_n,
    input  [3:0]  waddr,
    input  [63:0] wdata,
    output reg [63:0] r0data,
    output reg [63:0] r1data
);

    // Register address constants
    localparam [3:0] R0 = 4'h0;
    localparam [3:0] R1 = 4'h1;
    localparam [3:0] R2 = 4'h2;
    localparam [3:0] R3 = 4'h3;
    localparam [3:0] R4 = 4'h4;
    localparam [3:0] R5 = 4'h5;
    localparam [3:0] R6 = 4'h6;
    localparam [3:0] R7 = 4'h7;
    localparam [3:0] R8 = 4'h8;
    localparam [3:0] R9 = 4'h9;
    localparam [3:0] RA = 4'hA;
    localparam [3:0] RB = 4'hB;
    localparam [3:0] RC = 4'hC;
    localparam [3:0] RD = 4'hD;
    localparam [3:0] RE = 4'hE;
    localparam [3:0] RF = 4'hF;

    // Write enable decode
    wire [15:0] R_en;

    assign R_en[0]  = wena & (waddr == R0);
    assign R_en[1]  = wena & (waddr == R1);
    assign R_en[2]  = wena & (waddr == R2);
    assign R_en[3]  = wena & (waddr == R3);
    assign R_en[4]  = wena & (waddr == R4);
    assign R_en[5]  = wena & (waddr == R5);
    assign R_en[6]  = wena & (waddr == R6);
    assign R_en[7]  = wena & (waddr == R7);
    assign R_en[8]  = wena & (waddr == R8);
    assign R_en[9]  = wena & (waddr == R9);
    assign R_en[10] = wena & (waddr == RA);
    assign R_en[11] = wena & (waddr == RB);
    assign R_en[12] = wena & (waddr == RC);
    assign R_en[13] = wena & (waddr == RD);
    assign R_en[14] = wena & (waddr == RE);
    assign R_en[15] = wena & (waddr == RF);

    // 16 independent register outputs
    wire [63:0] DFF_out_0;
    wire [63:0] DFF_out_1;
    wire [63:0] DFF_out_2;
    wire [63:0] DFF_out_3;
    wire [63:0] DFF_out_4;
    wire [63:0] DFF_out_5;
    wire [63:0] DFF_out_6;
    wire [63:0] DFF_out_7;
    wire [63:0] DFF_out_8;
    wire [63:0] DFF_out_9;
    wire [63:0] DFF_out_10;
    wire [63:0] DFF_out_11;
    wire [63:0] DFF_out_12;
    wire [63:0] DFF_out_13;
    wire [63:0] DFF_out_14;
    wire [63:0] DFF_out_15;

    // Instantiate 16 registers
    DFF_64_en U0  (R_en[0],  rst_n, wdata, CLK, DFF_out_0);
    DFF_64_en U1  (R_en[1],  rst_n, wdata, CLK, DFF_out_1);
    DFF_64_en U2  (R_en[2],  rst_n, wdata, CLK, DFF_out_2);
    DFF_64_en U3  (R_en[3],  rst_n, wdata, CLK, DFF_out_3);
    DFF_64_en U4  (R_en[4],  rst_n, wdata, CLK, DFF_out_4);
    DFF_64_en U5  (R_en[5],  rst_n, wdata, CLK, DFF_out_5);
    DFF_64_en U6  (R_en[6],  rst_n, wdata, CLK, DFF_out_6);
    DFF_64_en U7  (R_en[7],  rst_n, wdata, CLK, DFF_out_7);
    DFF_64_en U8  (R_en[8],  rst_n, wdata, CLK, DFF_out_8);
    DFF_64_en U9  (R_en[9],  rst_n, wdata, CLK, DFF_out_9);
    DFF_64_en U10 (R_en[10], rst_n, wdata, CLK, DFF_out_10);
    DFF_64_en U11 (R_en[11], rst_n, wdata, CLK, DFF_out_11);
    DFF_64_en U12 (R_en[12], rst_n, wdata, CLK, DFF_out_12);
    DFF_64_en U13 (R_en[13], rst_n, wdata, CLK, DFF_out_13);
    DFF_64_en U14 (R_en[14], rst_n, wdata, CLK, DFF_out_14);
    DFF_64_en U15 (R_en[15], rst_n, wdata, CLK, DFF_out_15);

    // ======================================================
    // Read logic (combinational)
    // ======================================================
    always @(*) begin
        case (r0addr)
            R0: r0data = DFF_out_0;
            R1: r0data = DFF_out_1;
            R2: r0data = DFF_out_2;
            R3: r0data = DFF_out_3;
            R4: r0data = DFF_out_4;
            R5: r0data = DFF_out_5;
            R6: r0data = DFF_out_6;
            R7: r0data = DFF_out_7;
            R8: r0data = DFF_out_8;
            R9: r0data = DFF_out_9;
            RA: r0data = DFF_out_10;
            RB: r0data = DFF_out_11;
            RC: r0data = DFF_out_12;
            RD: r0data = DFF_out_13;
            RE: r0data = DFF_out_14;
            RF: r0data = DFF_out_15;
            default: r0data = 64'b0;
        endcase

        case (r1addr)
            R0: r1data = DFF_out_0;
            R1: r1data = DFF_out_1;
            R2: r1data = DFF_out_2;
            R3: r1data = DFF_out_3;
            R4: r1data = DFF_out_4;
            R5: r1data = DFF_out_5;
            R6: r1data = DFF_out_6;
            R7: r1data = DFF_out_7;
            R8: r1data = DFF_out_8;
            R9: r1data = DFF_out_9;
            RA: r1data = DFF_out_10;
            RB: r1data = DFF_out_11;
            RC: r1data = DFF_out_12;
            RD: r1data = DFF_out_13;
            RE: r1data = DFF_out_14;
            RF: r1data = DFF_out_15;
            default: r1data = 64'b0;
        endcase
    end

endmodule
