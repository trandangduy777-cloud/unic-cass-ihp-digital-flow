// I2C master 1 byte: ghi (START, dia chi+W, ACK, du lieu, ACK, STOP) hoac doc (START, dia chi+R, ACK, du lieu, NACK, STOP).
// SDA/SCL kieu open-drain: *_low = 1 nghia la keo duong xuong 0, = 0 la tha noi (len 1 nho tro keo len).
// Khong ho tro keo dai xung clock (clock stretching) va multi-master.
// CLK_DIV = so chu ky clk cho 1/4 chu ky SCL.
module i2c_master #(parameter CLK_DIV = 8) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,        // xung 1 chu ky khi busy = 0
    input  wire       rw,           // 0 ghi, 1 doc
    input  wire [6:0] addr,
    input  wire [7:0] wdata,
    output reg  [7:0] rdata,
    output reg        busy,
    output reg        done,         // xung 1 chu ky khi ket thuc (sau STOP)
    output reg        ack_err,      // 1 neu slave khong ACK
    input  wire       sda_in,
    output wire       sda_low,
    output wire       scl_low
);
    localparam S_IDLE = 3'd0, S_START = 3'd1, S_ADDR = 3'd2, S_AACK = 3'd3,
               S_DATA = 3'd4, S_DACK = 3'd5, S_STOP = 3'd6;
    localparam CW = $clog2(CLK_DIV) + 1;

    reg [2:0]    state;
    reg [1:0]    ph;
    reg [CW-1:0] cnt;
    reg [3:0]    bitcnt;
    reg [7:0]    sh;
    reg          rw_q;
    reg [7:0]    wd_q;

    wire step = (cnt == CLK_DIV - 1);

    reg sda_l, scl_l;
    always @(*) begin
        sda_l = 1'b0; scl_l = 1'b0;
        case (state)
            S_START: begin scl_l = (ph == 2'd3); sda_l = (ph >= 2'd1); end
            S_ADDR:  begin scl_l = (ph == 2'd0) || (ph == 2'd3); sda_l = ~sh[7]; end
            S_AACK:  begin scl_l = (ph == 2'd0) || (ph == 2'd3); sda_l = 1'b0; end
            S_DATA:  begin scl_l = (ph == 2'd0) || (ph == 2'd3); sda_l = rw_q ? 1'b0 : ~sh[7]; end
            S_DACK:  begin scl_l = (ph == 2'd0) || (ph == 2'd3); sda_l = 1'b0; end
            S_STOP:  begin scl_l = (ph == 2'd0); sda_l = (ph <= 2'd1); end
            default: begin end
        endcase
    end
    assign sda_low = sda_l;
    assign scl_low = scl_l;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE; ph <= 2'd0; cnt <= 0; bitcnt <= 4'd0; sh <= 8'h00;
            rw_q <= 1'b0; wd_q <= 8'h00; rdata <= 8'h00; busy <= 1'b0; done <= 1'b0; ack_err <= 1'b0;
        end else begin
            done <= 1'b0;
            if (state == S_IDLE) begin
                if (start && !busy) begin
                    busy <= 1'b1; ack_err <= 1'b0; rw_q <= rw; wd_q <= wdata;
                    sh <= {addr, rw}; state <= S_START; ph <= 2'd0; cnt <= 0; bitcnt <= 4'd0;
                end
            end else begin
                if (!step) cnt <= cnt + 1'b1;
                else begin
                    cnt <= 0;
                    ph  <= ph + 2'd1;
                    // lay mau o cuoi pha 2 (SCL dang cao)
                    if (ph == 2'd2) begin
                        if (state == S_AACK || (state == S_DACK && !rw_q))
                            if (sda_in) ack_err <= 1'b1;
                        if (state == S_DATA && rw_q) sh <= {sh[6:0], sda_in};
                    end
                    // het pha 3: chuyen trang thai
                    if (ph == 2'd3) begin
                        case (state)
                            S_START: begin state <= S_ADDR; bitcnt <= 4'd0; end
                            S_ADDR: begin
                                sh <= {sh[6:0], 1'b0}; bitcnt <= bitcnt + 4'd1;
                                if (bitcnt == 4'd7) state <= S_AACK;
                            end
                            S_AACK: begin
                                if (ack_err) state <= S_STOP;
                                else begin
                                    state <= S_DATA; bitcnt <= 4'd0;
                                    sh <= rw_q ? 8'h00 : wd_q;
                                end
                            end
                            S_DATA: begin
                                bitcnt <= bitcnt + 4'd1;
                                if (!rw_q) sh <= {sh[6:0], 1'b0};
                                if (bitcnt == 4'd7) begin
                                    state <= S_DACK;
                                    if (rw_q) rdata <= sh;
                                end
                            end
                            S_DACK: state <= S_STOP;
                            S_STOP: begin state <= S_IDLE; busy <= 1'b0; done <= 1'b1; end
                            default: state <= S_IDLE;
                        endcase
                    end
                end
            end
        end
    end
endmodule
