// Define the ID stage pipeline
// ID regs: Rs, Rt (目前只用到了lw和sw指令)

module reg_MEM (
	input clk,
	input rst_n,
	input en_reg,
	
	input WRegEn_in, 		// 目前的opcode
	input [63:0] Dout_in,	// 从D-MEM取出的data
	input [3:0] WReg1_in,
	
	output reg WRegEn, 		// 当写回寄存器的时候，Write enable信号跟着回来（例如lw）	
	output reg [63:0] Dout,
	output reg [3:0] WReg1
);

always @(posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		WRegEn	<= 	4'b0;	
		Dout  	<= 	64'b0;
		WReg1   <= 	4'b0;
	end else if (en_reg) begin
		WRegEn	<= 	WRegEn_in;	
		Dout  	<= 	Dout_in;
		WReg1   <= 	WReg1_in;
	end
end

endmodule 
