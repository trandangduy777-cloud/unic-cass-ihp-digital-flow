// SPI master, mode 0 (CPOL=0, CPHA=0), 8 bit, MSB truoc.
// CLK_DIV = so chu ky clk trong nua chu ky SCLK.
module spi_master #(parameter CLK_DIV = 8) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,      // xung 1 chu ky, chi nhan khi busy = 0
    input  wire [7:0] tx_data,
    input  wire       miso,
    output reg        sclk,
    output wire       mosi,
    output reg        cs_n,
    output reg        busy,
    output reg        done,       // xung 1 chu ky khi xong
    output reg  [7:0] rx_data
);
    localparam CW = $clog2(CLK_DIV) + 1;
    reg [CW-1:0] cnt;
    reg [7:0]    sh;
    reg [2:0]    bitcnt;

    assign mosi = sh[7];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk <= 1'b0; cs_n <= 1'b1; busy <= 1'b0; done <= 1'b0;
            rx_data <= 8'h00; cnt <= 0; sh <= 8'h00; bitcnt <= 3'd0;
        end else begin
            done <= 1'b0;
            if (!busy) begin
                if (start) begin
                    busy <= 1'b1; cs_n <= 1'b0; sh <= tx_data;
                    cnt <= 0; bitcnt <= 3'd0; sclk <= 1'b0;
                end
            end else begin
                if (cnt == CLK_DIV - 1) begin
                    cnt  <= 0;
                    sclk <= ~sclk;
                    if (!sclk) begin
                        // canh len: lay mau MISO
                        rx_data <= {rx_data[6:0], miso};
                    end else begin
                        // canh xuong: dich bit tiep theo
                        sh     <= {sh[6:0], 1'b0};
                        bitcnt <= bitcnt + 3'd1;
                        if (bitcnt == 3'd7) begin
                            busy <= 1'b0; cs_n <= 1'b1; done <= 1'b1;
                        end
                    end
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
        end
    end
endmodule
