// Ghep master va slave noi voi nhau (loopback) de chay qua LibreLane.
module spi_top (
    input  wire       clk,
    input  wire       rst_n,
    // phia master
    input  wire       start,
    input  wire [7:0] m_tx,
    output wire [7:0] m_rx,
    output wire       m_busy,
    output wire       m_done,
    // phia slave
    input  wire [7:0] s_tx,
    output wire [7:0] s_rx,
    output wire       s_valid
);
    wire sclk, mosi, miso, cs_n;
    spi_master #(.CLK_DIV(8)) u_m (
        .clk(clk), .rst_n(rst_n), .start(start), .tx_data(m_tx), .miso(miso),
        .sclk(sclk), .mosi(mosi), .cs_n(cs_n), .busy(m_busy), .done(m_done), .rx_data(m_rx));
    spi_slave u_s (
        .clk(clk), .rst_n(rst_n), .sclk(sclk), .mosi(mosi), .cs_n(cs_n),
        .tx_data(s_tx), .miso(miso), .rx_data(s_rx), .rx_valid(s_valid));
endmodule
