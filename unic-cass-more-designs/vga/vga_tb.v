`timescale 1ns/1ps
module vga_tb;
    reg clk = 0, rst_n = 0;
    wire hsync, vsync, active;
    wire [9:0] x, y;
    wire [2:0] r, g, b;
    vga_ctrl dut (.clk(clk), .rst_n(rst_n), .hsync(hsync), .vsync(vsync), .active(active),
                  .x(x), .y(y), .r(r), .g(g), .b(b));
    always #20 clk = ~clk;   // 25 MHz

    integer errors = 0;
    integer cyc = 0;
    integer line_len = 0, hs_low = 0, act_in_line = 0;
    integer vs_low_lines = 0, frame_clks = 0, frame_active = 0, frames = 0;
    reg prev_hs = 1, prev_vs = 1;
    integer first_hs_fall = -1, second_hs_fall = -1;
    integer first_vs_fall = -1, second_vs_fall = -1;
    integer hs_width = -1, vs_width_clk = -1, hs_cnt = 0, vs_cnt = 0;
    reg [2:0] exp_rgb;

    function [2:0] bar_rgb(input integer xx);
        integer k;
        begin
            k = xx / 80;
            case (k) 0: bar_rgb = 3'b111; 1: bar_rgb = 3'b110; 2: bar_rgb = 3'b011; 3: bar_rgb = 3'b010;
                     4: bar_rgb = 3'b101; 5: bar_rgb = 3'b100; 6: bar_rgb = 3'b001; default: bar_rgb = 3'b000; endcase
        end
    endfunction

    always @(posedge clk) if (rst_n) begin
        cyc = cyc + 1;
        // do chieu rong xung dong bo
        if (!hsync) hs_cnt = hs_cnt + 1;
        if (hsync && !prev_hs) begin if (hs_width < 0) hs_width = hs_cnt; if (hs_cnt !== 96) begin errors = errors + 1; $display("LOI hsync rong %0d", hs_cnt); end hs_cnt = 0; end
        if (!vsync) vs_cnt = vs_cnt + 1;
        if (vsync && !prev_vs) begin if (vs_cnt !== 2*800) begin errors = errors + 1; $display("LOI vsync rong %0d clk", vs_cnt); end vs_width_clk = vs_cnt; vs_cnt = 0; end
        // chu ky dong va khung
        if (!hsync && prev_hs) begin
            if (first_hs_fall < 0) first_hs_fall = cyc;
            else begin
                if (cyc - second_hs_fall !== 800 && second_hs_fall >= 0) begin errors = errors + 1; $display("LOI chu ky dong %0d", cyc - second_hs_fall); end
                second_hs_fall = cyc;
            end
            if (first_hs_fall >= 0 && second_hs_fall < 0) second_hs_fall = cyc;
        end
        if (!vsync && prev_vs) begin
            if (first_vs_fall < 0) first_vs_fall = cyc;
            else begin
                if (cyc - first_vs_fall !== 800*525) begin errors = errors + 1; $display("LOI chu ky khung %0d", cyc - first_vs_fall); end
                frames = frames + 1;
                first_vs_fall = cyc;
            end
        end
        // vung hien thi dung kich thuoc
        if (active) begin
            frame_active = frame_active + 1;
            if (x >= 640 || y >= 480) begin errors = errors + 1; $display("LOI active ngoai vung x=%0d y=%0d", x, y); end
            exp_rgb = bar_rgb(x);
            if ({r[2], g[2], b[2]} !== exp_rgb || {r[0], g[0], b[0]} !== exp_rgb) begin errors = errors + 1; $display("LOI mau x=%0d", x); end
        end else begin
            if (r !== 0 || g !== 0 || b !== 0) begin errors = errors + 1; $display("LOI: co mau ngoai vung hien thi"); end
        end
        // so diem hien thi moi khung: dem khi vsync xuong
        if (!vsync && prev_vs && frames >= 1) begin
            if (frame_active !== 640*480 * 1 && frames >= 2) begin errors = errors + 1; $display("LOI diem hien thi/khung = %0d", frame_active); end
            frame_active = 0;
        end
        prev_hs = hsync; prev_vs = vsync;
    end

    initial begin
        repeat (5) @(posedge clk);
        rst_n = 1;
        // chay 4 khung hinh
        repeat (800*525*4 + 1000) @(posedge clk);
        if (frames < 3) begin errors = errors + 1; $display("LOI: khong du khung de kiem (%0d)", frames); end
        if (errors == 0) $display("VGA: PASS (%0d khung, 0 loi)", frames);
        else             $display("VGA: FAIL (%0d loi)", errors);
        $finish;
    end
endmodule
