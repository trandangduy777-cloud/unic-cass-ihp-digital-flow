// PWM 8 bit. duty 0..255 -> muc cao duty/256 chu ky. duty doi tai bien chu ky (khong gay nhieu).
module pwm (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [7:0] duty,
    output reg        pwm_out
);
    reg [7:0] cnt;
    reg [7:0] duty_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 8'd0; duty_q <= 8'd0; pwm_out <= 1'b0;
        end else if (!en) begin
            cnt <= 8'd0; pwm_out <= 1'b0;
        end else begin
            cnt <= cnt + 8'd1;
            if (cnt == 8'd255) duty_q <= duty;
            pwm_out <= (cnt < duty_q);
        end
    end
endmodule
