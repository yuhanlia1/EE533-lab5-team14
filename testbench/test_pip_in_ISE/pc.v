// program counters

module pc #(parameter WIDTH = 9)(
	input clk, 
	input rst_n,
	input en_reg,
	
	output [WIDTH-1:0] pc_next
);

reg [WIDTH-1:0] pc_next_r;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		pc_next_r <= {WIDTH{1'b0}};
	end else if (en_reg) begin
		pc_next_r <= pc_next_r + {{(WIDTH-1){1'b0}}, 1'b1}; 
	end
end

assign pc_next = pc_next_r; 

endmodule