#!/bin/bash
# Chay mo phong RTL cua ca 5 khoi bang iverilog. Moi testbench in PASS hoac FAIL.
cd "$(dirname "$0")"
set -e
run() { # thu_muc  testbench  nguon...
  d=$1; tb=$2; shift 2
  (cd $d && iverilog -g2012 -o sim_out $tb "$@" && vvp sim_out | grep -E "PASS|FAIL" | head -1)
}
run spi  spi_tb.v  spi_top.v spi_master.v spi_slave.v
run i2c  i2c_tb.v  i2c_master.v
run fifo fifo_tb.v sync_fifo.v
run pwm  pwm_tb.v  pwm.v
run vga  vga_tb.v  vga_ctrl.v
