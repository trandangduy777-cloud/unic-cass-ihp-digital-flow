
`timescale 1ns/1ps
module lfsr_tb;
  reg clk = 0, rst_n = 0, ena = 1;
  reg [7:0] ui_in = 0, uio_in = 0;
  wire [7:0] uo_out, uio_out, uio_oe;
  integer errors = 0, i, uniq;
  reg [7:0] m_l; reg m_x;
  reg [255:0] seen;
  tt_um_lfsr_stevej dut (.ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
    .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n));
  always #10 clk = ~clk;
  always @(posedge clk) begin
    if (!rst_n) begin m_l <= 8'hFF; m_x <= 1'b0; end
    else if (uio_in[0]) m_l <= ui_in;
    else begin m_l <= {m_l[6:0], m_x}; m_x <= m_l[7] ^ m_l[6]; end
  end
  task step; begin @(posedge clk); #1;
    if (uo_out !== m_l) begin errors = errors + 1; $display("FAIL t=%0t out=%h model=%h", $time, uo_out, m_l); end
  end endtask
  initial begin
    $dumpfile("lfsr_tb.vcd"); $dumpvars(0, lfsr_tb);
    repeat (3) @(posedge clk); #1; rst_n = 1;
    seen = 0; uniq = 0;
    for (i = 0; i < 20; i = i + 1) begin
      step; $display("out %0d = %h", i, uo_out);
      if (!seen[uo_out]) begin seen[uo_out] = 1; uniq = uniq + 1; end
    end
    if (uniq > 17) $display("ok   %0d gia tri khac nhau trong 20 mau", uniq);
    else begin errors = errors + 1; $display("FAIL chi co %0d gia tri khac nhau", uniq); end
    ui_in = 8'h50; uio_in = 8'h01; step;
    uio_in = 8'h00;
    if (uo_out === 8'h50) $display("ok   nap seed 50 -> out = %h", uo_out);
    else begin errors = errors + 1; $display("FAIL nap seed: out = %h", uo_out); end
    for (i = 0; i < 20; i = i + 1) step;
    ui_in = 8'hA5; uio_in = 8'h01; step; uio_in = 8'h00;
    if (uo_out === 8'hA5) $display("ok   nap seed A5 -> out = %h", uo_out);
    else begin errors = errors + 1; $display("FAIL nap seed A5: out = %h", uo_out); end
    for (i = 0; i < 100; i = i + 1) step;
    $display("lfsr: %0d loi", errors);
    $finish;
  end
endmodule
