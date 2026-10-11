`timescale 1ns/1ps
// Testbench co mo hinh slave I2C (dia chi 0x42, 1 thanh ghi 8 bit) tren duong open-drain.
module i2c_tb;
    reg clk = 0, rst_n = 0, start = 0, rw = 0;
    reg [6:0] addr = 0;
    reg [7:0] wdata = 0;
    wire [7:0] rdata;
    wire busy, done, ack_err;
    wire m_sda_low, m_scl_low;
    reg  s_sda_low = 0;

    wire sda = (m_sda_low | s_sda_low) ? 1'b0 : 1'b1;   // dien tro keo len
    wire scl = m_scl_low ? 1'b0 : 1'b1;

    i2c_master #(.CLK_DIV(8)) dut (.clk(clk), .rst_n(rst_n), .start(start), .rw(rw), .addr(addr),
        .wdata(wdata), .rdata(rdata), .busy(busy), .done(done), .ack_err(ack_err),
        .sda_in(sda), .sda_low(m_sda_low), .scl_low(m_scl_low));
    always #5 clk = ~clk;

    // ---------- mo hinh slave ----------
    localparam [6:0] SLAVE_ADDR = 7'h42;
    reg [7:0] reg_mem = 8'h00;
    integer starts_seen = 0, stops_seen = 0;
    reg slave_busy = 0;

    task slave_get_byte(output [7:0] b);
        integer i;
        begin
            b = 0;
            for (i = 0; i < 8; i = i + 1) begin @(posedge scl); b = {b[6:0], sda}; end
            @(negedge scl);
        end
    endtask
    task slave_ack(input ack);
        begin
            #1 s_sda_low = ack;           // keo xuong = ACK
            @(posedge scl); @(negedge scl);
            #1 s_sda_low = 0;
        end
    endtask

    reg [7:0] a_byte, d_byte;
    integer i;
    always @(negedge sda) if (scl && !slave_busy) begin
        slave_busy = 1; starts_seen = starts_seen + 1;
        slave_get_byte(a_byte);
        if (a_byte[7:1] == SLAVE_ADDR) begin
            slave_ack(1);
            if (!a_byte[0]) begin                     // ghi
                slave_get_byte(d_byte);
                reg_mem = d_byte;
                slave_ack(1);
            end else begin                            // doc
                for (i = 7; i >= 0; i = i - 1) begin
                    #1 s_sda_low = ~reg_mem[i];
                    @(negedge scl);
                end
                #1 s_sda_low = 0;
                @(posedge scl); @(negedge scl);       // bit NACK cua master
            end
        end else begin
            slave_ack(0);                              // khong dung dia chi: NACK
        end
        slave_busy = 0;
    end
    always @(posedge sda) if (scl) stops_seen = stops_seen + 1;

    // ---------- kiem tra ----------
    integer errors = 0, tests = 0;
    task run(input r, input [6:0] a, input [7:0] d);
        begin
            rw = r; addr = a; wdata = d;
            @(posedge clk); #1 start = 1;
            @(posedge clk); #1 start = 0;
            wait (done);
            repeat (4) @(posedge clk);
            tests = tests + 1;
        end
    endtask

    integer k, s0;
    reg [7:0] v;
    initial begin
        repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);
        // ghi roi doc lai
        run(0, 7'h42, 8'h5A);
        if (ack_err) begin errors = errors + 1; $display("LOI: ack_err khi ghi dung dia chi"); end
        if (reg_mem !== 8'h5A) begin errors = errors + 1; $display("LOI: slave nhan %h, ky vong 5A", reg_mem); end
        run(1, 7'h42, 8'h00);
        if (ack_err) begin errors = errors + 1; $display("LOI: ack_err khi doc"); end
        if (rdata !== 8'h5A) begin errors = errors + 1; $display("LOI: doc duoc %h, ky vong 5A", rdata); end
        // nhieu gia tri
        for (k = 0; k < 16; k = k + 1) begin
            v = $random;
            run(0, 7'h42, v);
            if (ack_err || reg_mem !== v) begin errors = errors + 1; $display("LOI ghi %h -> %h", v, reg_mem); end
            run(1, 7'h42, 8'h00);
            if (ack_err || rdata !== v) begin errors = errors + 1; $display("LOI doc %h <- %h", rdata, v); end
        end
        // sai dia chi: phai bao ack_err va khong ghi vao slave
        v = reg_mem;
        run(0, 7'h13, 8'hEE);
        if (!ack_err) begin errors = errors + 1; $display("LOI: sai dia chi nhung khong bao ack_err"); end
        if (reg_mem !== v) begin errors = errors + 1; $display("LOI: slave bi ghi khi sai dia chi"); end
        // sau do van hoat dong binh thuong
        run(0, 7'h42, 8'hC3);
        if (ack_err || reg_mem !== 8'hC3) begin errors = errors + 1; $display("LOI: khong hoi phuc sau loi dia chi"); end
        // moi giao dich phai co dung 1 START va 1 STOP
        if (starts_seen !== tests || stops_seen < tests) begin errors = errors + 1; $display("LOI: START=%0d STOP=%0d so giao dich=%0d", starts_seen, stops_seen, tests); end
        if (errors == 0) $display("I2C: PASS (%0d giao dich, 0 loi)", tests);
        else             $display("I2C: FAIL (%0d loi)", errors);
        $finish;
    end
    initial begin #20_000_000; $display("I2C: FAIL (timeout)"); $finish; end
endmodule
