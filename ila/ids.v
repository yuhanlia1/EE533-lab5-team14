///////////////////////////////////////////////////////////////////////////////
// Module: ids.v
// [Modified] Added Custom Logic Analyzer for State & Data Tracing
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module ids 
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      input  [DATA_WIDTH-1:0]             in_data,
      input  [CTRL_WIDTH-1:0]             in_ctrl,
      input                               in_wr,
      output                              in_rdy,

      output [DATA_WIDTH-1:0]             out_data,
      output [CTRL_WIDTH-1:0]             out_ctrl,
      output                              out_wr,
      input                               out_rdy,
      
      // --- Register interface
      input                               reg_req_in,
      input                               reg_ack_in,
      input                               reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]      reg_src_in,

      output                              reg_req_out,
      output                              reg_ack_out,
      output                              reg_rd_wr_L_out,
      output [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_out,
      output [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_out,
      output [UDP_REG_SRC_WIDTH-1:0]      reg_src_out,

      // misc
      input                               reset,
      input                               clk
   );

   // Log2 Function
   function integer calc_log2;
      input integer value;
      integer i;
      begin
         i = 0;
         while (2**i < value) begin
            i = i + 1;
         end
         calc_log2 = i;
      end
   endfunction

   //------------------------- Signals -------------------------------
   
   wire [DATA_WIDTH-1:0]         in_fifo_data;
   wire [CTRL_WIDTH-1:0]         in_fifo_ctrl;
   wire                          in_fifo_nearly_full;
   wire                          in_fifo_empty;

   reg                           in_fifo_rd_en;
   reg                           out_wr_int;

   // software registers 
   wire [31:0]                   pattern_high;
   wire [31:0]                   pattern_low;
   wire [31:0]                   ids_cmd;
   
   // hardware registers
   reg [31:0]                    matches;

   // internal state
   reg [1:0]                     state, state_next;
   reg [31:0]                    matches_next;
   reg                           in_pkt_body, in_pkt_body_next;
   reg                           end_of_pkt, end_of_pkt_next;
   reg                           begin_pkt, begin_pkt_next;
   reg [2:0]                     header_counter, header_counter_next;

   // matcher signals
   wire                          matcher_match;
   wire                          matcher_reset;
   wire                          matcher_en, matcher_ce;

   //------------------------------------------------------------
   // 1. 定义 Logic Analyzer 参数
   //------------------------------------------------------------
   localparam LA_MEM_DEPTH = 256;
   localparam LA_ADDR_WIDTH = calc_log2(LA_MEM_DEPTH);
   // 宽度定义: 64bit Data + 2bit State + 3bit HeaderCnt + 1bit Match = 70 bits
   // 我们用 72 bits 对齐，剩下 2 bits 保留
   localparam LA_WIDTH = 72; 

   // Memory Array
   reg [LA_WIDTH-1:0] trace_mem [0:LA_MEM_DEPTH-1];
   
   // Pointers
   reg [LA_ADDR_WIDTH-1:0] trace_w_ptr;  // 硬件写指针
   wire [31:0]             trace_r_addr; // 软件读地址 (来自寄存器)

   // Output Buffers (拆分为3个32位寄存器供软件读取)
   reg [31:0] trace_out_data_lo; // 数据低32位
   reg [31:0] trace_out_data_hi; // 数据高32位
   reg [31:0] trace_out_debug;   // 状态+计数器+匹配位
   reg [LA_WIDTH-1:0] raw_trace_read;

   //------------------------------------------------------------
   // State machine parameters
   //------------------------------------------------------------
   parameter START   = 2'b00;
   parameter HEADER  = 2'b01;
   parameter PAYLOAD = 2'b10;

   //------------------------- Local assignments -------------------------------

   assign in_rdy      = !in_fifo_nearly_full;
   assign matcher_en  = in_pkt_body;
   assign matcher_ce  = (!in_fifo_empty && out_rdy);
   assign matcher_reset = (reset || ids_cmd[0] || end_of_pkt);

   //------------------------------------------------------------
   // 2. 捕获逻辑 (Capture Logic)
   //------------------------------------------------------------
   always @(posedge clk) begin
      if (reset) begin
         trace_w_ptr <= 0;
      end
      // 触发条件：当输入 FIFO 有数据读出，且正在处理时 (in_fifo_rd_en)
      // 或者是当有数据写入 Drop FIFO 时 (out_wr_int)
      // 这里我们选择 capturing when we decide to write to drop_fifo (out_wr_int)
      else if (out_wr_int) begin
         // 饱和写入：存满了就停，方便看最初的包
         if (trace_w_ptr < LA_MEM_DEPTH - 1) begin
             // 组合我们要监控的信号
             trace_mem[trace_w_ptr] <= { 
                 2'b00,              // [71:70] Padding
                 matcher_match,      // [69]    匹配信号
                 header_counter,     // [68:66] 计数器
                 state,              // [65:64] 状态机
                 in_fifo_data        // [63:0]  原始数据
             };
             trace_w_ptr <= trace_w_ptr + 1;
         end
      end
      // 如果需要 reset 重新抓取，可以利用 ids_cmd[1] 来重置指针 (可选功能)
      else if (ids_cmd[1]) begin
         trace_w_ptr <= 0;
      end
   end

   //------------------------------------------------------------
   // 3. 读取逻辑 (Read Logic)
   //------------------------------------------------------------
   always @(posedge clk) begin
      // 根据软件设置的地址读取 RAM
      raw_trace_read = trace_mem[trace_r_addr[LA_ADDR_WIDTH-1:0]];
      
      // 拆分到寄存器
      trace_out_data_lo <= raw_trace_read[31:0];
      trace_out_data_hi <= raw_trace_read[63:32];
      trace_out_debug   <= {24'b0, raw_trace_read[71:64]}; 
      // 注意：trace_out_debug 的低8位包含了我们存的 state/counter/match
   end

   //------------------------- Modules -------------------------------

   fallthrough_small_fifo #(
      .WIDTH(CTRL_WIDTH+DATA_WIDTH),
      .MAX_DEPTH_BITS(2)
   ) input_fifo (
      .din           ({in_ctrl, in_data}),
      .wr_en         (in_wr),
      .rd_en         (in_fifo_rd_en),
      .dout          ({in_fifo_ctrl, in_fifo_data}),
      .full          (),
      .nearly_full   (in_fifo_nearly_full),
      .empty         (in_fifo_empty),
      .reset         (reset),
      .clk           (clk)
   );

   detect7B matcher (
      .ce            (matcher_ce),
      .match_en      (matcher_en),
      .clk           (clk),
      .pipe1         ({in_ctrl, in_data}),
      .hwregA        ({pattern_high, pattern_low}),
      .match         (matcher_match),
      .mrst          (matcher_reset)
   );

   dropfifo drop_fifo (
      .clk           (clk), 
      .drop_pkt      (matcher_match && end_of_pkt),
      .fiforead      (out_rdy), 
      .fifowrite     (out_wr_int), 
      .firstword     (begin_pkt), 
      .in_fifo       ({in_fifo_ctrl,in_fifo_data}), 
      .lastword      (end_of_pkt), 
      .rst           (reset), 
      .out_fifo      ({out_ctrl,out_data}), 
      .valid_data    (out_wr)
   );

   generic_regs
   #( 
      .UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
      .TAG                 (`IDS_BLOCK_ADDR),
      .REG_ADDR_WIDTH      (`IDS_REG_ADDR_WIDTH),
      .NUM_COUNTERS        (0),
      
      // 修改寄存器数量
      // 软件寄存器 (SW->HW): 原3个 + 1个读地址 = 4个
      .NUM_SOFTWARE_REGS   (4),
      
      // 硬件寄存器 (HW->SW): 原1个 + 3个LA数据 = 4个
      .NUM_HARDWARE_REGS   (4)
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

      // --- SW regs interface
      // 顺序映射 
      // Reg 3: trace_r_addr (LA 读地址)
      // Reg 2: ids_cmd
      // Reg 1: pattern_low
      // Reg 0: pattern_high
      .software_regs    ({
                           trace_r_addr,
                           ids_cmd, 
                           pattern_low, 
                           pattern_high
                        }),

      // --- HW regs interface
      // 顺序映射
      // Reg 3: trace_out_debug (包含 State/Match)
      // Reg 2: trace_out_data_hi
      // Reg 1: trace_out_data_lo
      // Reg 0: matches
      .hardware_regs    ({
                           trace_out_debug,
                           trace_out_data_hi,
                           trace_out_data_lo,
                           matches
                        }),

      .clk              (clk),
      .reset            (reset)
    );

   //------------------------- Logic (Original FSM) -------------------------------
   // (这部分逻辑保持不变)
   always @(*) begin
      state_next = state;
      matches_next = matches;
      header_counter_next = header_counter;
      in_fifo_rd_en = 0;
      out_wr_int = 0;
      
      end_of_pkt_next = end_of_pkt;
      in_pkt_body_next = in_pkt_body;
      begin_pkt_next = begin_pkt;
      
      if (!in_fifo_empty && out_rdy) begin
         out_wr_int = 1;
         in_fifo_rd_en = 1;
         
         case(state)
            START: begin
               if (in_fifo_ctrl != 0) begin
                  state_next = HEADER;
                  begin_pkt_next = 1;
                  end_of_pkt_next = 0;
               end
            end
            HEADER: begin
               begin_pkt_next = 0;
               if (in_fifo_ctrl == 0) begin
                  header_counter_next = header_counter + 1'b1;
                  if (header_counter_next == 3) begin
                     state_next = PAYLOAD;
                  end
               end
            end
            PAYLOAD: begin
               if (in_fifo_ctrl != 0) begin
                  state_next = START;
                  header_counter_next = 0;
                  if (matcher_match) begin
                     matches_next = matches + 1;
                  end
                  end_of_pkt_next = 1;
                  in_pkt_body_next = 0;
               end
               else begin
                  in_pkt_body_next = 1;
               end
            end
         endcase
      end
   end
   
   always @(posedge clk) begin
      if(reset) begin
         matches <= 0;
         header_counter <= 0;
         state <= START;
         begin_pkt <= 0;
         end_of_pkt <= 0;
         in_pkt_body <= 0;
      end
      else begin
         if (ids_cmd[0]) matches <= 0;
         else matches <= matches_next;
         
         header_counter <= header_counter_next;
         state <= state_next;
         begin_pkt <= begin_pkt_next;
         end_of_pkt <= end_of_pkt_next;
         in_pkt_body <= in_pkt_body_next;
      end 
   end 

endmodule