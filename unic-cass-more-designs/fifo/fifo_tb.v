`timescale 1ns/1ps
module fifo_tb;
    localparam W = 8, AW = 4, D = 16;
    reg clk = 0, rst_n = 0, wr_en = 0, rd_en = 0;
    reg [W-1:0] wr_data = 0;
    wire [W-1:0] rd_data;
    wire full, empty;
    wire [AW:0] count;
    sync_fifo #(.WIDTH(W), .AW(AW)) dut (.clk(clk), .rst_n(rst_n), .wr_en(wr_en), .wr_data(wr_data),
        .rd_en(rd_en), .rd_data(rd_data), .full(full), .empty(empty), .count(count));
    always #5 clk = ~clk;

    // mo hinh tham chieu
    reg [W-1:0] ref_mem [0:1023];
    integer rh = 0, rt = 0;       // dau, duoi (tang dan)
    reg [W-1:0] ref_rd = 0;
    integer errors = 0, cycles = 0, writes = 0, reads = 0, i;

    integer ref_count; reg ref_full, ref_empty;
    always @(posedge clk) if (rst_n) begin
        // so sanh truoc canh clock (trang thai dang co)
        ref_count = rt - rh;
        ref_full  = (ref_count == D);
        ref_empty = (ref_count == 0);
        if (full !== ref_full)   begin errors = errors + 1; $display("LOI full t=%0t", $time); end
        if (empty !== ref_empty) begin errors = errors + 1; $display("LOI empty t=%0t", $time); end
        if (count !== ref_count) begin errors = errors + 1; $display("LOI count %0d vs %0d", count, ref_count); end
        if (rd_data !== ref_rd)  begin errors = errors + 1; $display("LOI rd_data %h vs %h t=%0t", rd_data, ref_rd, $time); end
        // cap nhat mo hinh
        if (wr_en && !ref_full)  begin ref_mem[rt % 1024] = wr_data; rt = rt + 1; writes = writes + 1; end
        if (rd_en && !ref_empty) begin ref_rd = ref_mem[rh % 1024]; rh = rh + 1; reads = reads + 1; end
        cycles = cycles + 1;
    end

    task drive(input w, input r, input [W-1:0] d);
        begin @(negedge clk); wr_en = w; rd_en = r; wr_data = d; end
    endtask

    integer seed = 7;
    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;
        // 1) doc khi rong
        drive(0,1,0); drive(0,1,0);
        // 2) ghi day roi ghi them (tran)
        for (i = 0; i < D + 4; i = i + 1) drive(1,0,i + 8'h10);
        // 3) doc het roi doc them (doc rong)
        for (i = 0; i < D + 4; i = i + 1) drive(0,1,0);
        // 4) vua ghi vua doc
        for (i = 0; i < 40; i = i + 1) drive(1,1,$random(seed));
        // 5) ngau nhien nhieu thien huong
        for (i = 0; i < 3000; i = i + 1) drive(($random(seed) % 3) != 0, ($random(seed) % 3) != 0, $random(seed));
        for (i = 0; i < 3000; i = i + 1) drive(($random(seed) % 4) == 0, ($random(seed) % 4) != 0, $random(seed));
        drive(0,0,0); drive(0,0,0); drive(0,0,0);
        if (writes < 100 || reads < 100) begin errors = errors + 1; $display("LOI: tb khong du bao phu"); end
        if (errors == 0) $display("FIFO: PASS (%0d chu ky, %0d ghi, %0d doc)", cycles, writes, reads);
        else             $display("FIFO: FAIL (%0d loi)", errors);
        $finish;
    end
endmodule
