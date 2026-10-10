`timescale 1ns/1ps
module uart_tx_tb;
  localparam CPB = 8;
  reg clk = 0, rst = 1, start = 0;
  reg [7:0] data = 0;
  wire tx, busy;
  integer errors = 0, i, k;
  reg [7:0] got;
  uart_tx uut (.clk(clk), .rst(rst), .start(start), .data(data), .tx(tx), .busy(busy));
  always #5 clk = ~clk;

  task send_and_check(input [7:0] b);
    begin
      data = b;
      @(posedge clk); start <= 1;
      @(posedge clk); start <= 0;
      if (tx !== 1'b0) @(negedge tx);
      repeat (CPB / 2) @(posedge clk);
      if (tx !== 1'b0) begin errors = errors + 1; $display("FAIL start bit"); end
      for (i = 0; i < 8; i = i + 1) begin
        repeat (CPB) @(posedge clk);
        got[i] = tx;
      end
      repeat (CPB) @(posedge clk);
      if (tx !== 1'b1) begin errors = errors + 1; $display("FAIL stop bit"); end
      if (got !== b) begin errors = errors + 1; $display("FAIL sent %h got %h", b, got); end
      else $display("ok   sent %h got %h", b, got);
      while (busy) @(posedge clk);
      repeat (3) @(posedge clk);
    end
  endtask

  initial begin
    $dumpfile("uart_tx_gl_tb.vcd");
    $dumpvars(0, uart_tx_tb);
    repeat (3) @(posedge clk);
    rst <= 0;
    repeat (3) @(posedge clk);
    send_and_check(8'h55); send_and_check(8'hAA); send_and_check(8'h00);
    send_and_check(8'hFF); send_and_check(8'h41); send_and_check(8'h7E);
    for (k = 0; k < 10; k = k + 1) send_and_check($urandom % 256);
    $display("uart_tx: %0d loi", errors);
    $finish;
  end
endmodule
