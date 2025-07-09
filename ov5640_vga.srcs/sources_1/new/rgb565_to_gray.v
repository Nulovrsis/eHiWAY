`timescale 1ns / 1ps
module rgb565_to_gray(
        input  wire        clk,
        input  wire        rst_n,
        input  wire [15:0] rgb565_in,   // 输入：RGB565像素数据
        input  wire        pixel_valid, // 输入：像素数据有效
        output reg  [7:0]  gray_out,    // 输出：8位灰度像素
        output reg         gray_valid   // 输出：灰度像素有效
    );
    // 拆分RGB565
    wire [4:0] r = rgb565_in[15:11];
    wire [5:0] g = rgb565_in[10:5];
    wire [4:0] b = rgb565_in[4:0];

    // 扩展到8位
    wire [7:0] r8 = {r, 3'b000};
    wire [7:0] g8 = {g, 2'b00};
    wire [7:0] b8 = {b, 3'b000};

    // 灰度加权和
    wire [15:0] gray_tmp = r8 * 8'd76 + g8 * 8'd150 + b8 * 8'd30;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_out   <= 8'd0;
            gray_valid <= 1'b0;
        end
        else if (pixel_valid) begin
            gray_out   <= gray_tmp[15:8]; // 右移8位即除256
            gray_valid <= 1'b1;
        end
        else begin
            gray_valid <= 1'b0;
        end
    end
endmodule
