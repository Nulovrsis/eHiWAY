`timescale 1ns / 1ps
module gray_32x32_sampler(
        input  wire        clk,           // 像素时钟（ov5640_pclk）
        input  wire        rst_n,         // 复位
        input  wire [7:0]  gray_in,       // 灰度像素输入
        input  wire        gray_valid,    // 灰度像素有效
        input  wire        ov5640_href,   // 行同步
        input  wire        ov5640_vsync,  // 场同步
        output reg  [7:0]  sampled_gray,  // 采样后灰度像素输出
        output reg         sampled_valid, // 采样像素有效
        output reg  [9:0]  sampled_addr   // 采样像素在32x32中的地址（0~1023）
    );
    // 行、列计数器
    reg [9:0] row_cnt;
    reg [9:0] col_cnt;
    reg       href_d;
    reg       vsync_d;

    // 行、列计数逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_cnt <= 0;
            col_cnt <= 0;
            href_d  <= 0;
            vsync_d <= 0;
        end
        else begin
            href_d  <= ov5640_href;
            vsync_d <= ov5640_vsync;
            if (ov5640_vsync) begin
                row_cnt <= 0;
                col_cnt <= 0;
            end
            else if (~href_d && ov5640_href) begin // 行开始
                col_cnt <= 0;
            end
            else if (ov5640_href && gray_valid) begin
                if (col_cnt == 639) begin
                    col_cnt <= 0;
                    if (row_cnt < 479)
                        row_cnt <= row_cnt + 1;
                end
                else begin
                    col_cnt <= col_cnt + 1;
                end
            end
        end
    end

    // 采样逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sampled_gray  <= 8'd0;
            sampled_valid <= 1'b0;
            sampled_addr  <= 10'd0;
        end
        else if (gray_valid && ov5640_href) begin
            // 跳采样：每隔15行、20列采一个像素
            if ((row_cnt % 15 == 0) && (col_cnt % 20 == 0) &&
                    (row_cnt/15 < 32) && (col_cnt/20 < 32)) begin
                sampled_gray  <= gray_in;
                sampled_valid <= 1'b1;
                sampled_addr  <= (row_cnt/15) * 32 + (col_cnt/20);
            end
            else begin
                sampled_valid <= 1'b0;
            end
        end
        else begin
            sampled_valid <= 1'b0;
        end
    end
endmodule

