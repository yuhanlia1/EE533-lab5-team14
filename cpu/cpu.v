// cpu 5-stage pipeline (RISC-V 暂定)
`timescale 1ns/1ps

`define PC_WIDTH 9

module cpu (
	input clk,
	input rst_n,
	input en_reg
);

// wires declaration
wire [`PC_WIDTH-1:0] pc;
wire [31:0] IF_ID_Din;

wire [31:0] IF_ID_Rout;


wire [63:0] ID_EX_Din_A;
wire [63:0] ID_EX_Din_B;


wire [63:0]ID_EX_R0_out;
wire [63:0]ID_EX_R1_out;
wire ID_EX_Wen_mm;
wire ID_EX_Wen_reg;
wire [3:0] ID_EX_Waddr;




wire [63:0]EX_MM_R0_in;
wire [63:0]EX_MM_R1_in;
wire [63:0]EX_MM_R0_out;
wire [63:0]EX_MM_R1_out;
wire [3:0] EX_MM_Waddr;
wire [3:0] EX_MM_Waddr_out;
wire EX_MM_Wen_reg;
wire EX_MM_Wen_mm;
wire EX_MM_Wen_reg_out;
wire EX_MM_Wen_mm_out;

wire [63:0]MM_WB_din;

wire [63:0] MEM_WB_out;
wire WB_wen;
wire [3:0] WB_waddr;

assign EX_MM_R0_in[63:0] = ID_EX_R0_out[63:0];
assign EX_MM_R1_in[63:0] = ID_EX_R1_out[63:0];
assign EX_MM_Waddr[3:0] = ID_EX_Waddr [3:0];
assign EX_MM_Wen_reg = ID_EX_Wen_reg;
assign EX_MM_Wen_mm  = ID_EX_Wen_mm;


pc pc0 ( 
	.clk(clk),
	.rst_n(rst_n),
	.en_reg(en_reg),
	.pc_next(pc)
);

Icache Imm(
	.clka(clk),
	.addra(pc),
	.douta(IF_ID_Din)
	
);

reg_IF IF_ID (
	.clk(clk),
	.rst_n(rst_n),
	.en_reg(en_reg),
	.instr(IF_ID_Din),
	.instr_out(IF_ID_Rout[31:0])
);

Regfiles regfiles0(
	.r0addr	(IF_ID_Rout[29:26]),
	.r1addr (IF_ID_Rout[25:22]),
	.wena   (WB_wen),
	.CLK    (clk),
	.rst_n  (rst_n),
	.waddr  (WB_waddr[3:0]),
	.wdata  (MEM_WB_out[63:0]),
	.r0data (ID_EX_Din_A[63:0]),
	.r1data (ID_EX_Din_B[63:0])
);

reg_ID ID_EX (
	.clk(clk),
	.rst_n(rst_n),
	.en_reg(en_reg),
	.WRegEn_in	(IF_ID_Rout[30]),
	.WMemEn_in	(IF_ID_Rout[31]),
	.r0data_in	(ID_EX_Din_A[63:0]),
	.r1data_in	(ID_EX_Din_B[63:0]),
	.WReg1_in 	(IF_ID_Rout[21:18]),
	
	.WRegEn   	(ID_EX_Wen_reg),
	.WMemEn   	(ID_EX_Wen_mm),
	.r0data   	(ID_EX_R0_out[63:0]),
	.r1data   	(ID_EX_R1_out[63:0]),
	.WReg1    	(ID_EX_Waddr [3:0])
);



reg_EX EX_MEM (
	.clk(clk),
	.rst_n(rst_n),
	.en_reg(en_reg),
	.WRegEn_in	(EX_MM_Wen_reg),
	.WMemEn_in	(EX_MM_Wen_mm),
	.r0data_in	(EX_MM_R0_in[63:0]),
	.r1data_in	(EX_MM_R1_in[63:0]),
	.WReg1_in 	(EX_MM_Waddr[3:0]),
			 	
	.WRegEn   	(EX_MM_Wen_reg_out),
	.WMemEn   	(EX_MM_Wen_mm_out),
	.r0data   	(EX_MM_R0_out[63:0]),
	.r1data   	(EX_MM_R1_out[63:0]),
	.WReg1    	(EX_MM_Waddr_out[3:0])
);


Dcache Dmm(
	.clka(clk),
	.dina(EX_MM_R1_out[63:0]),
	.addra(EX_MM_R0_out[8:0]),
	.wea(EX_MM_Wen_mm_out),
	.clkb(clk),
	.addrb(EX_MM_R0_out[8:0]),
	.doutb(MM_WB_din[63:0])
);


reg_MEM MEM_WB (
	.clk(clk),
	.rst_n(rst_n),
	.en_reg(en_reg),
	.WRegEn_in	(EX_MM_Wen_reg_out),
	.Dout_in	(MM_WB_din[63:0]),
	.WReg1_in 	(EX_MM_Waddr_out[3:0]),
			 
	.WRegEn   	(WB_wen),
	.Dout		(MEM_WB_out[63:0]),
	.WReg1    	(WB_waddr[3:0])
);

endmodule 


