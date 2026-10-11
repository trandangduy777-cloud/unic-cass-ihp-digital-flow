// Bo dieu khien VGA 640x480 @ 60 Hz. clk = xung diem anh 25.175 MHz (thuc te dung 25 MHz).
// Ngang: 640 hien + 16 truoc + 96 dong bo + 48 sau = 800
// Doc:   480 hien + 10 truoc + 2 dong bo  + 33 sau = 525
module vga_ctrl (
    input  wire       clk,
    input  wire       rst_n,
    output wire       hsync,        // muc thap khi dong bo
    output wire       vsync,        // muc thap khi dong bo
    output wire       active,       // 1 trong vung hien thi
    output wire [9:0] x,
    output wire [9:0] y,
    output wire [2:0] r,
    output wire [2:0] g,
    output wire [2:0] b
);
    localparam H_ACT = 640, H_FP = 16, H_SYNC = 96, H_BP = 48, H_TOT = 800;
    localparam V_ACT = 480, V_FP = 10, V_SYNC = 2,  V_BP = 33, V_TOT = 525;

    reg [9:0] hc, vc;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin hc <= 10'd0; vc <= 10'd0; end
        else if (hc == H_TOT - 1) begin
            hc <= 10'd0;
            vc <= (vc == V_TOT - 1) ? 10'd0 : vc + 10'd1;
        end else hc <= hc + 10'd1;
    end

    assign hsync  = ~((hc >= H_ACT + H_FP) && (hc < H_ACT + H_FP + H_SYNC));
    assign vsync  = ~((vc >= V_ACT + V_FP) && (vc < V_ACT + V_FP + V_SYNC));
    assign active = (hc < H_ACT) && (vc < V_ACT);
    assign x = hc;
    assign y = vc;

    // 8 thanh mau, moi thanh rong 80 diem: trang, vang, lo, luc, tim, do, lam, den
    wire [2:0] bar = (hc < 80) ? 3'd0 : (hc < 160) ? 3'd1 : (hc < 240) ? 3'd2 : (hc < 320) ? 3'd3 :
                     (hc < 400) ? 3'd4 : (hc < 480) ? 3'd5 : (hc < 560) ? 3'd6 : 3'd7;
    reg [2:0] rgb;
    always @(*) begin
        case (bar)
            3'd0: rgb = 3'b111;   // trang
            3'd1: rgb = 3'b110;   // vang
            3'd2: rgb = 3'b011;   // lo
            3'd3: rgb = 3'b010;   // luc
            3'd4: rgb = 3'b101;   // tim
            3'd5: rgb = 3'b100;   // do
            3'd6: rgb = 3'b001;   // lam
            default: rgb = 3'b000; // den
        endcase
    end
    assign r = active ? {3{rgb[2]}} : 3'd0;
    assign g = active ? {3{rgb[1]}} : 3'd0;
    assign b = active ? {3{rgb[0]}} : 3'd0;
endmodule
