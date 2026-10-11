// FIFO dong bo, du lieu doc ra duoc chot (rd_data cap nhat khi doc).
module sync_fifo #(parameter WIDTH = 8, parameter AW = 4) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             wr_en,
    input  wire [WIDTH-1:0] wr_data,
    input  wire             rd_en,
    output reg  [WIDTH-1:0] rd_data,
    output wire             full,
    output wire             empty,
    output wire [AW:0]      count
);
    localparam DEPTH = 1 << AW;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [AW:0] wptr, rptr;

    assign count = wptr - rptr;
    assign full  = (count == DEPTH);
    assign empty = (wptr == rptr);

    wire do_wr = wr_en && !full;
    wire do_rd = rd_en && !empty;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= 0; rptr <= 0; rd_data <= 0;
        end else begin
            if (do_wr) begin
                mem[wptr[AW-1:0]] <= wr_data;
                wptr <= wptr + 1'b1;
            end
            if (do_rd) begin
                rd_data <= mem[rptr[AW-1:0]];
                rptr <= rptr + 1'b1;
            end
        end
    end
endmodule
