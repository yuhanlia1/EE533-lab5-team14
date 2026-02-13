// Define the ID stage pipeline
// ID regs: Rs, Rt (目前只用到了lw和sw指令)

module reg_ID (
	input clk,
	input rst_n,
	input en_reg,
	
	input WRegEn_in, 	// 目前的opcode
	input WMemEn_in,
	input [63:0] r0data_in,	// 取出的data
	input [63:0] r1data_in,
	input [3:0] WReg1_in,
	
	output reg WRegEn, 	
	output reg WMemEn,
	output reg [63:0] r0data,
	output reg [63:0] r1data,
	output reg [3:0] WReg1
);

always @(posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		WRegEn	<= 	4'b0;	
		WMemEn  <= 	4'b0;
		r0data  <= 	64'b0;
		r1data  <= 	64'b0;
		WReg1   <= 	4'b0;
	end else if (en_reg) begin
		WRegEn	<= 	WRegEn_in;	
		WMemEn  <= 	WMemEn_in;
		r0data  <= 	r0data_in;
		r1data  <= 	r1data_in;
		WReg1   <= 	WReg1_in;
	end
end

endmodule 
