module div8 (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] n,
    input  wire [7:0] d,
    output reg  [7:0] q,
    output reg  [7:0] r,
    output reg        done,
    output reg        dbz
);
    reg [8:0] rem;
    reg [7:0] quo;
    reg [7:0] dvs;
    reg [3:0] cnt;
    reg       busy;

    wire [8:0] shifted = {rem[7:0], quo[7]};
    wire [9:0] diff    = {1'b0, shifted} - {2'b00, dvs};
    wire       neg     = diff[9];
    wire [8:0] rem_nx  = neg ? shifted : diff[8:0];
    wire [7:0] quo_nx  = {quo[6:0], ~neg};

    always @(posedge clk) begin
        if (rst) begin
            rem <= 9'd0; quo <= 8'd0; dvs <= 8'd0; cnt <= 4'd0;
            busy <= 1'b0; done <= 1'b0; dbz <= 1'b0; q <= 8'd0; r <= 8'd0;
        end else begin
            done <= 1'b0;
            if (!busy) begin
                if (start) begin
                    if (d == 8'd0) begin
                        dbz <= 1'b1; q <= 8'hFF; r <= n; done <= 1'b1;
                    end else begin
                        dbz <= 1'b0; rem <= 9'd0; quo <= n; dvs <= d;
                        cnt <= 4'd0; busy <= 1'b1;
                    end
                end
            end else begin
                rem <= rem_nx; quo <= quo_nx; cnt <= cnt + 1'b1;
                if (cnt == 4'd7) begin
                    busy <= 1'b0; done <= 1'b1; q <= quo_nx; r <= rem_nx[7:0];
                end
            end
        end
    end
endmodule
