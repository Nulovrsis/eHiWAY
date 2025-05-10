`timescale 1 ps/ 1 ps
module ov5640_vga_640x480
    (
        input wire sys_clk , // 系统时钟
        input wire sys_rst_n , // 系统复位，低电平有效
        //摄像头接口
        input wire ov5640_pclk , // 摄像头数据像素时钟
        input wire ov5640_vsync, // 摄像头场同步信号
        input wire ov5640_href , // 摄像头行同步信号
        input wire [7:0] ov5640_data , // 摄像头数据
        output wire ov5640_rst_n, // 摄像头复位信号，低电平有效
        output wire ov5640_pwdn , // 摄像头时钟选择信号, 1:使用摄像头自带的晶振
        output wire sccb_scl , // 摄像头SCCB_SCL线
        inout wire sccb_sda , // 摄像头SCCB_SDA线
        //SDRAM接口
        output wire sdram_clk , // SDRAM 时钟
        output wire sdram_cke , // SDRAM 时钟使能
        output wire sdram_cs_n , // SDRAM 片选
        output wire sdram_ras_n , // SDRAM 行有效
        output wire sdram_cas_n , // SDRAM 列有效
        output wire sdram_we_n , // SDRAM 写有效
        output wire [1:0] sdram_ba , // SDRAM Bank地址
        output wire [12:0] sdram_addr , // SDRAM 地址
        inout wire [15:0] sdram_dq , // SDRAM 数据
        //VGA接口
        output wire vga_hs , // 行同步信号
        output wire vga_vs , // 场同步信号
        output wire [15:0] vga_rgb ,// 红绿蓝三原色输出
        output wire xclk // 时钟输出
        // output wire cfg_done_out // 这是一个可选的输出，如果您需要从顶层观察 cfg_done
    );

    ////
    //\* Parameter and Internal Signal \//
    ////

    //parameter define
    parameter H_PIXEL = 24'd640 ; //水平方向像素个数,用于设置SDRAM缓存大小
    parameter V_PIXEL = 24'd480 ; //垂直方向像素个数,用于设置SDRAM缓存大小

    //wire define
    wire clk_100m ; //100MHz时钟,SDRAM操作时钟
    wire clk_100m_shift ; //100MHz时钟,SDRAM相位偏移时钟
    wire clk_25m ; //25MHz时钟,提供给vga驱动时钟
    wire locked ; //PLL锁定信号
    wire rst_n ; //复位信号(sys_rst_n & locked)
    wire cfg_done_raw ; // 从 ov5640_top_inst 出来的原始 cfg_done 信号 (在 i2c_clk 域)
    wire wr_en ; //sdram写使能
    wire [15:0] wr_data ; //sdram写数据
    wire rd_en ; //sdram读使能
    wire [15:0] rd_data ; //sdram读数据
    wire sdram_init_done_raw; // 从 sdram_top_inst 出来的原始 sdram_init_done 信号 (在 clk_100m 域)
    wire sys_init_done ; //系统初始化完成(SDRAM初始化+摄像头初始化)

    // **** CDC同步逻辑 for cfg_done ****
    reg cfg_done_pclk_s1; // 同步器第一级触发器
    reg cfg_done_pclk_s2; // 同步器第二级触发器 (cfg_done 同步到 ov5640_pclk 域)

    always @(posedge ov5640_pclk or negedge rst_n) begin
        if (!rst_n) begin
            cfg_done_pclk_s1 <= 1'b0;
            cfg_done_pclk_s2 <= 1'b0;
        end
        else begin
            cfg_done_pclk_s1 <= cfg_done_raw;   // 从 i2c_clk 域采样原始 cfg_done
            cfg_done_pclk_s2 <= cfg_done_pclk_s1; // 第二级同步
        end
    end
    // **** CDC同步逻辑结束 ****

    // **** 新增CDC同步逻辑 for sdram_init_done ****
    reg sdram_init_done_pclk_s1; // 同步器第一级
    reg sdram_init_done_pclk_s2; // 同步器第二级 (sdram_init_done 同步到 ov5640_pclk 域)

    always @(posedge ov5640_pclk or negedge rst_n) begin // 使用 ov5640_pclk 和相同的复位 rst_n
        if (!rst_n) begin
            sdram_init_done_pclk_s1 <= 1'b0;
            sdram_init_done_pclk_s2 <= 1'b0;
        end
        else begin
            sdram_init_done_pclk_s1 <= sdram_init_done_raw;   // 从 clk_100m 域采样原始 sdram_init_done
            sdram_init_done_pclk_s2 <= sdram_init_done_pclk_s1; // 第二级同步
        end
    end
    // **** CDC同步逻辑结束 ****


    ////
    //\* Main Code \//
    ////

    //rst_n:复位信号(sys_rst_n & locked)
    assign rst_n = sys_rst_n & locked;

    //sys_init_done:系统初始化完成(SDRAM初始化+摄像头初始化)
    // **** 修改这里，使用两个都同步到 ov5640_pclk 域的信号 ****
    assign sys_init_done = sdram_init_done_pclk_s2 & cfg_done_pclk_s2;

    //ov5640_rst_n:摄像头复位,固定高电平
    assign ov5640_rst_n = 1'b1;

    //ov5640_pwdn
    assign ov5640_pwdn = 1'b0;

    //------------- clk_gen_inst -------------
    clk_gen clk_gen_inst(
                .areset (~sys_rst_n ),
                .inclk0 (sys_clk ),
                .c0 (clk_100m ),
                .c1 (clk_100m_shift ),
                .c2 (clk_25m ),
                .c3 (xclk ), //时钟输出
                .locked (locked )
            );

    //------------- ov5640_top_inst -------------
    ov5640_top ov5640_top_inst(
                   .sys_clk (clk_25m ),
                   .sys_rst_n (rst_n ),
                   .sys_init_done (sys_init_done ),
                   .ov5640_pclk (ov5640_pclk ),
                   .ov5640_href (ov5640_href ),
                   .ov5640_vsync (ov5640_vsync ),
                   .ov5640_data (ov5640_data ),
                   .cfg_done (cfg_done_raw ),
                   .sccb_scl (sccb_scl ),
                   .sccb_sda (sccb_sda ),
                   .ov5640_wr_en (wr_en ),
                   .ov5640_data_out (wr_data )
               );

    //------------- sdram_top_inst -------------
    sdram_top sdram_top_inst(
                  .sys_clk (clk_100m ),
                  .clk_out (clk_100m_shift ),
                  .sys_rst_n (rst_n ),
                  //用户写端口
                  .wr_fifo_wr_clk (ov5640_pclk ),
                  .wr_fifo_wr_req (wr_en ),
                  .wr_fifo_wr_data (wr_data ),
                  .sdram_wr_b_addr (24'd0 ),
                  .sdram_wr_e_addr (H_PIXEL*V_PIXEL),
                  .wr_burst_len (10'd512 ),
                  .wr_rst (~rst_n ),
                  //用户读端口
                  .rd_fifo_rd_clk (clk_25m ),
                  .rd_fifo_rd_req (rd_en ),
                  .rd_fifo_rd_data (rd_data ),
                  .sdram_rd_b_addr (24'd0 ),
                  .sdram_rd_e_addr (H_PIXEL*V_PIXEL),
                  .rd_burst_len (10'd512 ),
                  .rd_rst (~rst_n ),
                  //用户控制端口
                  .read_valid (1'b1 ),
                  .pingpang_en (1'b1 ),
                  .init_end (sdram_init_done_raw), // SDRAM 初始化完成标志 (连接到原始的 sdram_init_done_raw)
                  //SDRAM 芯片接口
                  .sdram_clk (sdram_clk ),
                  .sdram_cke (sdram_cke ),
                  .sdram_cs_n (sdram_cs_n ),
                  .sdram_ras_n (sdram_ras_n ),
                  .sdram_cas_n (sdram_cas_n ),
                  .sdram_we_n (sdram_we_n ),
                  .sdram_ba (sdram_ba ),
                  .sdram_addr (sdram_addr ),
                  .sdram_dq (sdram_dq )
              );

    //------------- vga_ctrl_inst -------------
    vga_ctrl vga_ctrl_inst
             (
                 .vga_clk (clk_25m ),
                 .sys_rst_n (rst_n ),
                 .pix_data (rd_data ),
                 .pix_data_req (rd_en ),
                 .hsync (vga_hs ),
                 .vsync (vga_vs ),
                 .rgb (vga_rgb )
             );

endmodule
