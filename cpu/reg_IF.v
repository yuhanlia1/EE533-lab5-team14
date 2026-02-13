// Define the IF stage pipeline
// IF regs 只通过32-bit 指令，之后可能需要加PC（为了branch），或者flush，为了stall

module reg_IF (
	input clk, 
	input rst_n,
	input en_reg,
	
	input [31:0] instr,
	output [31:0] instr_out
);

reg [31:0] instr_out_r;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin 
		instr_out_r <= 32'b0;
	end else if (en_reg) begin
		instr_out_r <= instr;
	end	
end

assign instr_out = instr_out_r;

endmodule 