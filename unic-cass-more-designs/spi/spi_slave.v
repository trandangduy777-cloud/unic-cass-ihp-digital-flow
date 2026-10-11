// SPI slave, mode 0. Dong bo SCLK/CS_N/MOSI vao mien clk he thong,
// nen clk phai nhanh hon SCLK it nhat 4 lan.
module spi_slave (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sclk,
    input  wire       mosi,
    input  wire       cs_n,
    input  wire [7:0] tx_data,     // byte se gui di o lan truyen tiep theo (doc luc CS xuong)
    output wire       miso,
    output reg  [7:0] rx_data,
    output reg        rx_valid     // xung 1 chu ky khi nhan du 8 bit
);
    reg [2:0] sclk_s, cs_s, mosi_s;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin sclk_s <= 3'b000; cs_s <= 3'b111; mosi_s <= 3'b000; end
        else begin
            sclk_s <= {sclk_s[1:0], sclk};
            cs_s   <= {cs_s[1:0],  cs_n};
            mosi_s <= {mosi_s[1:0], mosi};
        end
    end
    wire sclk_rise = (sclk_s[2:1] == 2'b01);
    wire sclk_fall = (sclk_s[2:1] == 2'b10);
    wire cs_fall   = (cs_s[2:1]   == 2'b10);
    wire cs_active = ~cs_s[1];

    reg [7:0] sh_out;
    reg [7:0] sh_in;
    reg [2:0] cnt;
    assign miso = cs_active ? sh_out[7] : 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sh_out <= 8'h00; sh_in <= 8'h00; cnt <= 3'd0;
            rx_data <= 8'h00; rx_valid <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            if (cs_fall) begin
                sh_out <= tx_data; cnt <= 3'd0;
            end else if (cs_active) begin
                if (sclk_rise) begin
                    sh_in <= {sh_in[6:0], mosi_s[1]};
                    cnt   <= cnt + 3'd1;
                    if (cnt == 3'd7) begin
                        rx_data  <= {sh_in[6:0], mosi_s[1]};
                        rx_valid <= 1'b1;
                    end
                end
                if (sclk_fall) sh_out <= {sh_out[6:0], 1'b0};
            end
        end
    end
endmodule
