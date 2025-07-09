`timescale 1ns / 1ps
/********************************************************************
本模块: FSMC-SRAM控制器

描述:
带异步FSMC接口的SRAM控制器

注意：
无

协议:
FSMC SLAVE
MEM MASTER

作者: 陈家耀
日期: 2025/05/04
********************************************************************/


module async_fsmc_sram #(
	parameter real SIM_DELAY = 1 // 仿真延时
)(
	// 时钟和复位
	input wire aclk,
	input wire aresetn,
	
	// FSMC接口
	input wire fsmc_nex,
	input wire fsmc_nwe,
	input wire fsmc_noe,
	input wire[1:0] fsmc_nbl,
	input wire[15:0] fsmc_da_i,
	output wire[15:0] fsmc_da_o,
	output wire[15:0] fsmc_da_t, // 1为输入, 0为输出
	
	// SRAM接口
	output wire sram_clk,
	output wire sram_en,
	output wire[1:0] sram_wen,
	output wire[15:0] sram_addr,
	output wire[15:0] sram_din,
	input wire[15:0] sram_dout
);
	
	reg fsmc_nex_d1;
	reg fsmc_nex_d2;
	reg fsmc_nex_d3;
	reg fsmc_nwe_d1;
	reg fsmc_nwe_d2;
	reg fsmc_nwe_d3;
	reg fsmc_noe_d1;
	reg fsmc_noe_d2;
	reg fsmc_noe_d3;
	reg[15:0] fsmc_addr_latched;
	reg[1:0] fsmc_nbl_latched;
	wire on_fsmc_nex_neg;
	reg on_fsmc_nex_neg_d1;
	wire on_fsmc_nwe_pos;
	
	assign fsmc_da_o = sram_dout;
	assign fsmc_da_t = {16{fsmc_nex | fsmc_noe}};
	
	assign sram_clk = aclk;
	assign sram_en = on_fsmc_nex_neg_d1 | ((~fsmc_nex_d2) & on_fsmc_nwe_pos);
	assign sram_wen = {2{on_fsmc_nwe_pos}} & (~fsmc_nbl_latched);
	assign sram_addr = fsmc_addr_latched;
	assign sram_din = fsmc_da_i;
	
	assign on_fsmc_nex_neg = (~fsmc_nex_d2) & fsmc_nex_d3;
	assign on_fsmc_nwe_pos = fsmc_nwe_d2 & (~fsmc_nwe_d3);
	
	always @(posedge aclk or negedge aresetn)
	begin
		if(~aresetn)
		begin
			{fsmc_nex_d3, fsmc_nex_d2, fsmc_nex_d1} <= 3'b111;
			{fsmc_nwe_d3, fsmc_nwe_d2, fsmc_nwe_d1} <= 3'b111;
			{fsmc_noe_d3, fsmc_noe_d2, fsmc_noe_d1} <= 3'b111;
		end
		else
		begin
			{fsmc_nex_d3, fsmc_nex_d2, fsmc_nex_d1} <= # SIM_DELAY {fsmc_nex_d2, fsmc_nex_d1, fsmc_nex};
			{fsmc_nwe_d3, fsmc_nwe_d2, fsmc_nwe_d1} <= # SIM_DELAY {fsmc_nwe_d2, fsmc_nwe_d1, fsmc_nwe};
			{fsmc_noe_d3, fsmc_noe_d2, fsmc_noe_d1} <= # SIM_DELAY {fsmc_noe_d2, fsmc_noe_d1, fsmc_noe};
		end
	end
	
	always @(posedge aclk or negedge aresetn)
	begin
		if(~aresetn)
			on_fsmc_nex_neg_d1 <= 1'b0;
		else
			on_fsmc_nex_neg_d1 <= # SIM_DELAY on_fsmc_nex_neg;
	end
	
	always @(posedge aclk)
	begin
		if(on_fsmc_nex_neg)
		begin
			fsmc_addr_latched <= # SIM_DELAY fsmc_da_i;
			fsmc_nbl_latched <= # SIM_DELAY fsmc_nbl;
		end
	end
	
endmodule
