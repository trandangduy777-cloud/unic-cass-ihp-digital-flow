`timescale 1ns/1ps
module pwm_tb;
    reg clk = 0, rst_n = 0, en = 0;
    reg [7:0] duty = 0;
    wire pwm_out;
    pwm dut (.clk(clk), .rst_n(rst_n), .en(en), .duty(duty), .pwm_out(pwm_out));
    always #5 clk = ~clk;
    integer errors = 0, tests = 0, i, hi, k;

    // dem so chu ky muc cao trong 'n' chu ky lien tiep
    task count_high(input integer n, output integer h);
        integer j;
        begin h = 0; for (j = 0; j < n; j = j + 1) begin @(posedge clk); #1 if (pwm_out) h = h + 1; end end
    endtask

    task check(input [7:0] d);
        integer h1, h2;
        begin
            duty = d;
            count_high(256 * 2, h1);     // 2 chu ky de duty moi chac chan co hieu luc
            count_high(256, h2);
            tests = tests + 1;
            if (h2 !== d) begin errors = errors + 1; $display("LOI duty=%0d: dem %0d", d, h2); end
        end
    endtask

    integer h, lastpos;
    initial begin
        repeat (3) @(posedge clk); rst_n = 1;
        // en = 0 thi ra thap
        count_high(300, h);
        if (h !== 0) begin errors = errors + 1; $display("LOI: en=0 nhung pwm_out len"); end
        en = 1;
        check(0); check(1); check(64); check(128); check(200); check(255);
        for (k = 0; k < 20; k = k + 1) check($random);
        // doi duty giua chu ky: chu ky hien tai khong doi
        duty = 8'd100; count_high(512, h);
        duty = 8'd30;
        // ngay sau lenh doi, 1 chu ky day du dau tien phai co the van la 100 (neu doi giua chu ky)
        // sau 2 chu ky thi bat buoc la 30
        count_high(256, h);
        count_high(256, h);
        count_high(256, h);
        tests = tests + 1;
        if (h !== 30) begin errors = errors + 1; $display("LOI: doi duty giua chu ky khong dung (%0d)", h); end
        // tat en
        wait (pwm_out === 1'b1); @(posedge clk);   // tat dung luc ngo ra dang o muc cao
        en = 0; count_high(300, h);
        tests = tests + 1;
        if (h > 1) begin errors = errors + 1; $display("LOI: tat en nhung pwm_out van cao (%0d)", h); end
        if (errors == 0) $display("PWM: PASS (%0d kiem tra, 0 loi)", tests);
        else             $display("PWM: FAIL (%0d loi)", errors);
        $finish;
    end
endmodule
