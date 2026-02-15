`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:26:17 02/13/2026
// Design Name:   cpu
// Module Name:   C:/Documents and Settings/student/Desktop/lab4/tb/tb_cpu.v
// Project Name:  tb
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: cpu
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////


module cpu_tb;

  localparam integer CLK_HALF = 10;   // 100MHz => 10ns period
  localparam integer N_CYCLES  = 80;  // ?????? store/load + WB

  reg clk;
  reg rst_n;
  reg en_reg;

  cpu dut (
    .clk(clk),
    .rst_n(rst_n),
    .en_reg(en_reg)
  );

  // clock
  initial begin
    clk = 1'b0;
    forever #CLK_HALF clk = ~clk;
  end

  // reset + enable
  initial begin
    rst_n  = 1'b0;
    en_reg = 1'b0;

    // ????????
    repeat (3) @(posedge clk);
    rst_n <= 1'b1;

    // ???????
    repeat (1) @(posedge clk);
    en_reg <= 1'b1;
  end

  // ============================================================
  // Dcache ?????? load ????
  // ???? Dcache ? Xilinx ? blk_mem ???????????????? memory?
  // ??????????????????????????????? load ???? mif ???/? X?
  // ============================================================
  initial begin
    // ?? reset release
    wait(rst_n === 1'b1);
    @(posedge clk);

    // ???????????? 0x00,0x01,0x02...?
    // ??????????????????????
    // dut.Dmm.inst ?? Dcache ? BLK_MEM_GEN_V2_7 ???? inst
    // ?????? RAM ??????????????????
    //
    // ?????????mem[0]=0x111..., mem[1]=0x222..., ...
    begin : TRY_INIT
      integer i;
      for (i = 0; i < 8; i = i + 1) begin
        // ?? Xilinx behavioral ?? "mem" ? "memory" ??
        // ????????????????????????????
        // dut.Dmm.inst.mem[i] = 64'h1111_1111_1111_1111 * (i+1);
      end
    end
  end

  // ============================================================
  // ???? pipeline ???? posedge?
  // ============================================================
  integer cycle;
  initial cycle = 0;

  always @(posedge clk) begin
    cycle <= cycle + 1;

    $display("==================================================================");
    $display("CYCLE %0d  t=%0t  rst_n=%b  en_reg=%b", cycle, $time, rst_n, en_reg);

    // PC / IF stage
    $display("[IF ] PC=%0d  Icache_dout(IF_ID_Din)=0x%08h", dut.pc, dut.IF_ID_Din);

    // IF/ID pipeline reg output
    $display("[IF/ID] IF_ID_Rout=0x%08h  {WMemEn,WRegEn}=%b%b  r0addr=%0d r1addr=%0d waddr=%0d",
             dut.IF_ID_Rout,
             dut.IF_ID_Rout[31], dut.IF_ID_Rout[30],
             dut.IF_ID_Rout[29:26], dut.IF_ID_Rout[25:22], dut.IF_ID_Rout[21:18]);

    // Regfile read (combinational read outputs going into ID/EX)
    $display("[ID ] RF_r0data(ID_EX_Din_A)=0x%016h  RF_r1data(ID_EX_Din_B)=0x%016h",
             dut.ID_EX_Din_A, dut.ID_EX_Din_B);

    // ID/EX pipeline reg outputs
    $display("[ID/EX] Wen_reg=%b Wen_mm=%b  Waddr=%0d  R0=0x%016h  R1=0x%016h",
             dut.ID_EX_Wen_reg, dut.ID_EX_Wen_mm, dut.ID_EX_Waddr,
             dut.ID_EX_R0_out, dut.ID_EX_R1_out);

    // EX/MEM pipeline reg outputs (??? EX ?? pass-through)
    $display("[EX/MEM] Wen_reg=%b Wen_mm=%b  Waddr=%0d  R0=0x%016h  R1=0x%016h",
             dut.EX_MM_Wen_reg_out, dut.EX_MM_Wen_mm_out, dut.EX_MM_Waddr_out,
             dut.EX_MM_R0_out, dut.EX_MM_R1_out);

    // MEM stage: Dcache read data
    $display("[MEM] Dcache_addr=%0d  store_data=0x%016h  wea=%b  load_data(MM_WB_din)=0x%016h",
             dut.EX_MM_R0_out[8:0], dut.EX_MM_R1_out, dut.EX_MM_Wen_mm_out, dut.MM_WB_din);

    // MEM/WB pipeline reg outputs (writeback controls)
    $display("[MEM/WB] WB_wen=%b  WB_waddr=%0d  WB_data(MEM_WB_out)=0x%016h",
             dut.WB_wen, dut.WB_waddr, dut.MEM_WB_out);

    // ?????
    if (cycle >= N_CYCLES) begin
      $display("Reached max cycles (%0d). Finish.", N_CYCLES);
      $finish;
    end
  end

  // optional: dump waves (for gtkwave / etc)
  initial begin
    // ?????? ModelSim/Questa?????????? add wave
    $dumpfile("cpu_tb.vcd");
    $dumpvars(0, cpu_tb);
  end

endmodule
