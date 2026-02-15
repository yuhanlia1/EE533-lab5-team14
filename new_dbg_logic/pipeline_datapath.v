`timescale 1ns/1ps
`include "../include/registers.v"

module pipeline_datapath
#(
    parameter DATA_WIDTH = 64,
    parameter CTRL_WIDTH = DATA_WIDTH/8,
    parameter PC_WIDTH = 9,
    parameter UDP_REG_SRC_WIDTH = 2
)
(
    input                                clk,
    input                                reset,

    input  [DATA_WIDTH-1:0]              in_data,
    input  [CTRL_WIDTH-1:0]              in_ctrl,
    input                                in_wr,
    output                               in_rdy,

    output [DATA_WIDTH-1:0]              out_data,
    output [CTRL_WIDTH-1:0]              out_ctrl,
    output                               out_wr,
    input                                out_rdy,

    input                               reg_req_in,
    input                               reg_ack_in,
    input                               reg_rd_wr_L_in,
    input  [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_in,
    input  [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_in,
    input  [UDP_REG_SRC_WIDTH-1:0]      reg_src_in,

    output                              reg_req_out,
    output                              reg_ack_out,
    output                              reg_rd_wr_L_out,
    output  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_out,
    output  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_out,
    output  [UDP_REG_SRC_WIDTH-1:0]     reg_src_out
);

assign out_data = in_data;
assign out_ctrl = in_ctrl;
assign out_wr   = in_wr;
assign in_rdy   = out_rdy;

wire rst_n;
assign rst_n = ~reset;

reg  [PC_WIDTH-1:0] pc;
wire [PC_WIDTH-1:0] pc_plus1;
assign pc_plus1 = pc + {{(PC_WIDTH-1){1'b0}},1'b1};

wire [31:0] IF_ID_Din;
wire [31:0] IF_ID_Rout;

wire [63:0] ID_EX_Din_A;
wire [63:0] ID_EX_Din_B;

wire [63:0] ID_EX_R0_out;
wire [63:0] ID_EX_R1_out;
wire        ID_EX_Wen_mm;
wire        ID_EX_Wen_reg;
wire [3:0]  ID_EX_Waddr;

wire [63:0] EX_MM_R0_in;
wire [63:0] EX_MM_R1_in;
wire [63:0] EX_MM_R0_out;
wire [63:0] EX_MM_R1_out;
wire [3:0]  EX_MM_Waddr;
wire [3:0]  EX_MM_Waddr_out;
wire        EX_MM_Wen_reg;
wire        EX_MM_Wen_mm;
wire        EX_MM_Wen_reg_out;
wire        EX_MM_Wen_mm_out;

wire [63:0] MM_WB_din;
wire [63:0] MEM_WB_out;
wire        WB_wen;
wire [3:0]  WB_waddr;

assign EX_MM_R0_in    = ID_EX_R0_out;
assign EX_MM_R1_in    = ID_EX_R1_out;
assign EX_MM_Waddr    = ID_EX_Waddr;
assign EX_MM_Wen_reg  = ID_EX_Wen_reg;
assign EX_MM_Wen_mm   = ID_EX_Wen_mm;

wire [31:0] sw_imem_ctrl;
wire [31:0] sw_imem_write;
wire [31:0] sw_imem_addr;
wire [31:0] sw_imem_wdata;

wire [31:0] sw_dmem_ctrl;
wire [31:0] sw_dmem_write;
wire [31:0] sw_dmem_addr;
wire [31:0] sw_dmem_wdata_hi;
wire [31:0] sw_dmem_wdata_lo;

reg  [31:0] hw_imem_rdata;
reg  [31:0] hw_dmem_r_data_hi;
reg  [31:0] hw_dmem_r_data_lo;

// --------------------------------------------------
// WB_en的定义+PC的定义
// --------------------------------------------------

wire imem_interact_en;
wire imem_sw_we;
wire dmem_interact_en;
wire dmem_sw_we;

assign imem_interact_en = sw_imem_ctrl[0];
assign imem_sw_we       = sw_imem_write[0];

assign dmem_interact_en = sw_dmem_ctrl[0];
assign dmem_sw_we       = sw_dmem_write[0];

wire core_enable;
assign core_enable = ~(imem_interact_en | dmem_interact_en);

wire en_reg;
assign en_reg = core_enable;

wire WB_wen_core;
assign WB_wen_core = WB_wen & core_enable;

always @(posedge clk) begin
    if (!rst_n) begin
        pc <= {PC_WIDTH{1'b0}};
    end else if (en_reg) begin
        pc <= pc_plus1;
    end
end

// --------------------------------------------------
// interact_en的定义 （选择是cpu自己转，还是写入指令）
// --------------------------------------------------

wire [PC_WIDTH-1:0] imem_addr_final;
wire [31:0]         imem_din_final;
wire                imem_we_final;

assign imem_addr_final = imem_interact_en ? sw_imem_addr[PC_WIDTH-1:0] : pc;
assign imem_din_final  = imem_interact_en ? sw_imem_wdata : 32'b0;
assign imem_we_final   = imem_interact_en ? imem_sw_we   : 1'b0;				//当en=0 即Imem变成ROM

wire [7:0]  dmem_addra_final;
wire [7:0]  dmem_addrb_final;
wire [63:0] dmem_din_final;
wire        dmem_we_final;

assign dmem_addra_final = dmem_interact_en ? sw_dmem_addr[7:0] : EX_MM_R0_out[7:0];
assign dmem_addrb_final = dmem_interact_en ? sw_dmem_addr[7:0] : EX_MM_R0_out[7:0];
assign dmem_din_final   = dmem_interact_en ? {sw_dmem_wdata_hi, sw_dmem_wdata_lo} : EX_MM_R1_out;
assign dmem_we_final    = dmem_interact_en ? dmem_sw_we : EX_MM_Wen_mm_out;

// --------------------------------------------------
// Logic to update hardware registers
// --------------------------------------------------
always @(posedge clk) begin
    if (!rst_n) begin
        hw_imem_rdata <= 32'hDEADBEEF;
    end else begin
        if (imem_interact_en && !imem_we_final) begin
            hw_imem_rdata <= IF_ID_Din;
        end
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        hw_dmem_r_data_lo <= 32'hDEADBEEF;
        hw_dmem_r_data_hi <= 32'hDEADBEEF;
    end else begin
        if (dmem_interact_en) begin
            hw_dmem_r_data_lo <= MM_WB_din[31:0];
            hw_dmem_r_data_hi <= MM_WB_din[63:32];
        end
    end
end

// --------------------------------------------------
// Debug code 
// --------------------------------------------------
wire [31:0] sw_dbg_regsel;

reg  [31:0] hw_dbg_rdata_lo;
reg  [31:0] hw_dbg_rdata_hi;
wire [63:0] dbg_rdata;

wire [3:0] dbg_raddr;
assign dbg_raddr = sw_dbg_regsel[3:0];

always @(posedge clk) begin
    if (!rst_n) begin
        hw_dbg_rdata_lo <= 32'hDEADBEEF;
        hw_dbg_rdata_hi <= 32'hDEADBEEF;
    end else begin
        hw_dbg_rdata_lo <= dbg_rdata[31:0];
        hw_dbg_rdata_hi <= dbg_rdata[63:32];
    end
end


// --------------------------------------------------
// Module instance
// --------------------------------------------------

Icache Imm(
    .clk(clk),
    .addr(imem_addr_final),
    .din(imem_din_final),
    .dout(IF_ID_Din),
    .we(imem_we_final)
);

reg_IF IF_ID (
    .clk(clk),
    .rst_n(rst_n),
    .en_reg(en_reg),
    .instr(IF_ID_Din),
    .instr_out(IF_ID_Rout[31:0])
);

Regfiles regfiles0(
    .r0addr (IF_ID_Rout[29:26]),
    .r1addr (IF_ID_Rout[25:22]),
    .wena   (WB_wen_core),
    .CLK    (clk),
    .rst_n  (rst_n),
	
	// Debug
	.dbg_addr (dbg_raddr),
    .dbg_data (dbg_rdata),
	
    .waddr  (WB_waddr[3:0]),
    .wdata  (MEM_WB_out[63:0]),
    .r0data (ID_EX_Din_A[63:0]),
    .r1data (ID_EX_Din_B[63:0])
);

reg_ID ID_EX (
    .clk(clk),
    .rst_n(rst_n),
    .en_reg(en_reg),
    .WRegEn_in  (IF_ID_Rout[30]),
    .WMemEn_in  (IF_ID_Rout[31]),
    .r0data_in  (ID_EX_Din_A[63:0]),
    .r1data_in  (ID_EX_Din_B[63:0]),
    .WReg1_in   (IF_ID_Rout[21:18]),

    .WRegEn     (ID_EX_Wen_reg),
    .WMemEn     (ID_EX_Wen_mm),
    .r0data     (ID_EX_R0_out[63:0]),
    .r1data     (ID_EX_R1_out[63:0]),
    .WReg1      (ID_EX_Waddr[3:0])
);

reg_EX EX_MEM (
    .clk(clk),
    .rst_n(rst_n),
    .en_reg(en_reg),
    .WRegEn_in  (EX_MM_Wen_reg),
    .WMemEn_in  (EX_MM_Wen_mm),
    .r0data_in  (EX_MM_R0_in[63:0]),
    .r1data_in  (EX_MM_R1_in[63:0]),
    .WReg1_in   (EX_MM_Waddr[3:0]),

    .WRegEn     (EX_MM_Wen_reg_out),
    .WMemEn     (EX_MM_Wen_mm_out),
    .r0data     (EX_MM_R0_out[63:0]),
    .r1data     (EX_MM_R1_out[63:0]),
    .WReg1      (EX_MM_Waddr_out[3:0])
);

Dcache Dmm(
    .clka   (clk),
    .dina   (dmem_din_final),
    .addra  (dmem_addra_final),
    .wea    (dmem_we_final),
    .clkb   (clk),
    .addrb  (dmem_addrb_final),
    .doutb  (MM_WB_din[63:0])
);

reg_MEM MEM_WB (
    .clk(clk),
    .rst_n(rst_n),
    .en_reg(en_reg),
    .WRegEn_in  (EX_MM_Wen_reg_out),
    .Dout_in    (MM_WB_din[63:0]),
    .WReg1_in   (EX_MM_Waddr_out[3:0]),

    .WRegEn     (WB_wen),
    .Dout       (MEM_WB_out[63:0]),
    .WReg1      (WB_waddr[3:0])
);

generic_regs
#(
    .UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
`ifdef PIPE_BLOCK_ADDR
    .TAG                 (`PIPE_BLOCK_ADDR),
    .REG_ADDR_WIDTH      (`PIPE_REG_ADDR_WIDTH),
`else
    .TAG                 (`PIPELINE_DATAPATH_BLOCK_ADDR),
    .REG_ADDR_WIDTH      (`PIPELINE_DATAPATH_REG_ADDR_WIDTH),
`endif
    .NUM_COUNTERS        (0),	
    .NUM_SOFTWARE_REGS   (10),			// 9 + 1 debug
    .NUM_HARDWARE_REGS   (5)			// 3+2 debug
) module_regs (
    .reg_req_in       (reg_req_in),
    .reg_ack_in       (reg_ack_in),
    .reg_rd_wr_L_in   (reg_rd_wr_L_in),
    .reg_addr_in      (reg_addr_in),
    .reg_data_in      (reg_data_in),
    .reg_src_in       (reg_src_in),

    .reg_req_out      (reg_req_out),
    .reg_ack_out      (reg_ack_out),
    .reg_rd_wr_L_out  (reg_rd_wr_L_out),
    .reg_addr_out     (reg_addr_out),
    .reg_data_out     (reg_data_out),
    .reg_src_out      (reg_src_out),

    .counter_updates  (),
    .counter_decrement(),

    .software_regs    ({
		sw_dbg_regsel,        // debug
		
        sw_dmem_wdata_lo,
        sw_dmem_wdata_hi,
        sw_dmem_addr,
        sw_dmem_write,
        sw_dmem_ctrl,
        sw_imem_wdata,
        sw_imem_addr,
        sw_imem_write,
        sw_imem_ctrl
    }),

    .hardware_regs    ({
		hw_dbg_rdata_lo,      // debug
		hw_dbg_rdata_hi,      // debug
		
        hw_dmem_r_data_lo,
        hw_dmem_r_data_hi,
        hw_imem_rdata
    }),

    .clk              (clk),
    .reset            (reset)
);

endmodule
