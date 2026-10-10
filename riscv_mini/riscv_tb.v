`timescale 1ns/1ps
module riscv_tb;
  reg clk = 0, rst_n = 0, ena = 1;
  reg [7:0] ui_in = 0, uio_in = 0;
  wire [7:0] uo_out, uio_out, uio_oe;
  integer errors = 0;
  tt_um_riscv_mini_ihp dut (.ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
    .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n));
  always #10 clk = ~clk;
  task exec(input [15:0] instr);
    begin
      ui_in = instr[7:0]; uio_in = instr[15:8];
      @(posedge clk); #1;
    end
  endtask
  task show(input [2:0] r, input [7:0] expect_v);
    begin
      ui_in = {r, 3'b000, 2'b11}; uio_in = 8'h00;
      #1;
      if (uo_out !== expect_v) begin
        errors = errors + 1;
        $display("FAIL x%0d: expected %0d got %0d", r, expect_v, uo_out);
      end else $display("ok   x%0d = %0d", r, uo_out);
    end
  endtask
  function [15:0] ltype(input [2:0] rd, input [7:0] imm);
    ltype = {imm[7:5], imm[4:0], 3'b000, rd, 2'b10};
  endfunction
  function [15:0] rtype(input [2:0] f3, input [1:0] f2, input [2:0] rd, input [2:0] rs1, input [2:0] rs2);
    rtype = {f3, f2, rs2, rs1, rd, 2'b00};
  endfunction
  function [15:0] itype(input [2:0] f3, input [2:0] rd, input [2:0] rs1, input [4:0] imm);
    itype = {f3, imm, rs1, rd, 2'b01};
  endfunction
  initial begin
    $dumpfile("riscv_tb.vcd"); $dumpvars(0, riscv_tb);
    repeat (3) @(posedge clk); #1; rst_n = 1;
    exec(ltype(3'd1, 8'd5));
    exec(ltype(3'd2, 8'd3));
    show(3'd1, 8'd5); show(3'd2, 8'd3);
    exec(rtype(3'b010, 2'b00, 3'd3, 3'd1, 3'd2)); show(3'd3, 8'd8);
    exec(rtype(3'b011, 2'b00, 3'd4, 3'd1, 3'd2)); show(3'd4, 8'd2);
    exec(rtype(3'b000, 2'b00, 3'd5, 3'd1, 3'd2)); show(3'd5, 8'd1);
    exec(rtype(3'b001, 2'b00, 3'd6, 3'd1, 3'd2)); show(3'd6, 8'd7);
    exec(itype(3'b010, 3'd7, 3'd1, 5'd10));       show(3'd7, 8'd15);
    exec(itype(3'b100, 3'd7, 3'd1, 5'd2));        show(3'd7, 8'd20);
    $display("riscv_mini: %0d loi", errors);
    $finish;
  end
endmodule
