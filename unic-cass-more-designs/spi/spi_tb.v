`timescale 1ns/1ps
module spi_tb;
    reg clk = 0, rst_n = 0, start = 0;
    reg [7:0] m_tx = 0, s_tx = 0;
    wire [7:0] m_rx, s_rx;
    wire m_busy, m_done, s_valid;
    integer errors = 0, n = 0;

    spi_top dut (.clk(clk), .rst_n(rst_n), .start(start), .m_tx(m_tx), .m_rx(m_rx),
                 .m_busy(m_busy), .m_done(m_done), .s_tx(s_tx), .s_rx(s_rx), .s_valid(s_valid));
    always #5 clk = ~clk;

    reg got_valid;
    reg [7:0] got_s_rx;
    always @(posedge clk) if (s_valid) begin got_valid <= 1; got_s_rx <= s_rx; end

    task xfer(input [7:0] a, input [7:0] b);
        begin
            m_tx = a; s_tx = b; got_valid = 0;
            @(posedge clk); #1 start = 1;
            @(posedge clk); #1 start = 0;
            wait (m_done);
            repeat (6) @(posedge clk);
            n = n + 1;
            if (m_rx !== b)       begin errors = errors + 1; $display("LOI: master nhan %h, ky vong %h", m_rx, b); end
            if (!got_valid)       begin errors = errors + 1; $display("LOI: slave khong bao rx_valid"); end
            else if (got_s_rx !== a) begin errors = errors + 1; $display("LOI: slave nhan %h, ky vong %h", got_s_rx, a); end
            if (m_busy !== 0)     begin errors = errors + 1; $display("LOI: busy van len"); end
        end
    endtask

    integer i;
    initial begin
        repeat (4) @(posedge clk);
        rst_n = 1;
        repeat (4) @(posedge clk);
        xfer(8'hA5, 8'h3C);
        xfer(8'h00, 8'hFF);
        xfer(8'hFF, 8'h00);
        xfer(8'h01, 8'h80);
        xfer(8'h80, 8'h01);
        for (i = 0; i < 20; i = i + 1) xfer($random, $random);
        if (errors == 0) $display("SPI: PASS (%0d lan truyen, 0 loi)", n);
        else             $display("SPI: FAIL (%0d loi)", errors);
        $finish;
    end
    initial begin #5_000_000; $display("SPI: FAIL (timeout)"); $finish; end
endmodule
