`timescale 1ns/1ps

module icache_tb;

  reg         clk;
  reg  [8:0]  addr;
  wire [31:0] dout;

  Icache dut (
    .addr(addr),
    .clk(clk),
    .dout(dout)
  );

  // 50MHz: 20ns period
  initial clk = 1'b0;
  always #10 clk = ~clk;

  integer i;

  function has_xz32(input [31:0] v);
    begin
      has_xz32 = (^v === 1'bx); // reduction XOR trick: X/Z -> X
    end
  endfunction

  initial begin
    addr = 9'd0;

    $display("============================================================");
    $display(" Icache TB start");
    $display(" Expect: dout should be stable 32-bit hex, not Z/X");
    $display(" Init file name inside IP: mif_file_16_1");
    $display("============================================================");

    repeat (2) @(posedge clk);

    for (i = 0; i < 32; i = i + 1) begin
      addr <= i[8:0];
      @(posedge clk);
      #1; 

      if (has_xz32(dout)) begin
        $display("t=%0t  addr=%0d  dout=%h  <-- X/Z DETECTED !!!", $time, addr, dout);
      end else begin
        $display("t=%0t  addr=%0d  dout=%h", $time, addr, dout);
      end
    end

    $display("============================================================");
    $display(" Icache TB done");
    $display("============================================================");
    $finish;
  end

endmodule
