`timescale 1ns/1ps
module div8_tb;
  reg clk = 0, rst = 1, start = 0;
  reg [7:0] n = 0, d = 0;
  wire [7:0] q, r;
  wire done, dbz;
  integer errors = 0, i;
  div8 uut (.clk(clk), .rst(rst), .start(start), .n(n), .d(d), .q(q), .r(r), .done(done), .dbz(dbz));
  always #5 clk = ~clk;

  task run(input [7:0] x, input [7:0] y);
    begin
      n = x; d = y;
      @(posedge clk); start <= 1;
      @(posedge clk); start <= 0;
      @(posedge done); #1;
      if (y == 0) begin
        if (!(dbz && q == 8'hFF && r == x)) begin
          errors = errors + 1; $display("FAIL %0d / 0", x);
        end else $display("ok   %0d / 0 -> dbz", x);
      end else if (q !== x / y || r !== x % y) begin
        errors = errors + 1;
        $display("FAIL %0d / %0d = %0d r %0d (expected %0d r %0d)", x, y, q, r, x / y, x % y);
      end else
        $display("ok   %0d / %0d = %0d r %0d", x, y, q, r);
    end
  endtask

  initial begin
    $dumpfile("div8_tb.vcd");
    $dumpvars(0, div8_tb);
    repeat (3) @(posedge clk);
    rst <= 0;
    run(100, 7); run(255, 1); run(255, 255); run(0, 5); run(5, 9); run(200, 0);
    for (i = 0; i < 20; i = i + 1) run($urandom % 256, 1 + $urandom % 255);
    $display("div8: %0d loi", errors);
    $finish;
  end
endmodule
