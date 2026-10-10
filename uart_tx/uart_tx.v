module uart_tx #(
    parameter CLKS_PER_BIT = 8
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx,
    output reg        busy
);
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [15:0] clk_cnt;
    reg [2:0] bit_idx;
    reg [7:0] shreg;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            clk_cnt <= 16'd0;
            bit_idx <= 3'd0;
            shreg <= 8'd0;
            tx <= 1'b1;
            busy <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    clk_cnt <= 16'd0;
                    bit_idx <= 3'd0;
                    if (start) begin
                        shreg <= data;
                        busy <= 1'b1;
                        tx <= 1'b0;
                        state <= START;
                    end else begin
                        busy <= 1'b0;
                    end
                end
                START: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 16'd0;
                        tx <= shreg[0];
                        shreg <= {1'b0, shreg[7:1]};
                        state <= DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 16'd0;
                        if (bit_idx == 3'd7) begin
                            tx <= 1'b1;
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                            tx <= shreg[0];
                            shreg <= {1'b0, shreg[7:1]};
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 16'd0;
                        busy <= 1'b0;
                        state <= IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end
            endcase
        end
    end
endmodule
