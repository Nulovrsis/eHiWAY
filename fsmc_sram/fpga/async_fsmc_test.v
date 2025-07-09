`timescale 1ns / 1ps
/********************************************************************
本模块: FSMC测试

描述:
异步FSMC接口测试

注意：
无

协议:
FSMC SLAVE

作者: 陈家耀
日期: 2025/05/04
********************************************************************/


module async_fsmc_test(
	// 外部晶振和外部复位
	input wire osc_clk,
	input wire ext_resetn,
	
	// FSMC接口
	input wire fsmc_cs,
	input wire fsmc_wr,
	input wire fsmc_rd,
	input wire[1:0] fsmc_nbl,
	inout wire[15:0] fsmc_data
);
	
	/** PLL **/
	wire pll0_clk_in;
	wire pll0_resetn_in;
	wire pll0_clk_out; // 100MHz
	wire pll0_locked;
	
	assign pll0_clk_in = osc_clk;
	assign pll0_resetn_in = ext_resetn;
	
	// 请例化PLL!
	/*
	pll_1 u_pll(
		.areset(~pll0_resetn_in),
		.inclk0(pll0_clk_in),
		.c0(pll0_clk_out),
		.locked(pll0_locked)
	);
	*/
	
	/** FSMC-SRAM控制器 **/
	// FSMC接口
	wire[15:0] fsmc_da_i;
	wire[15:0] fsmc_da_o;
	wire[15:0] fsmc_da_t; // 1为输入, 0为输出
	// SRAM接口
	wire sram_clk;
	wire sram_en;
	wire[1:0] sram_wen;
	wire[15:0] sram_addr;
	wire[15:0] sram_din;
	wire[15:0] sram_dout;
	
	genvar fsmc_da_id;
	generate
		for(fsmc_da_id = 0;fsmc_da_id < 16;fsmc_da_id = fsmc_da_id + 1)
		begin:fsmc_da_blk
			assign fsmc_da_i[fsmc_da_id] = fsmc_data[fsmc_da_id];
			assign fsmc_data[fsmc_da_id] = fsmc_da_t[fsmc_da_id] ? 1'bz:fsmc_da_o[fsmc_da_id];
		end
	endgenerate
	
	async_fsmc_sram #(
		.SIM_DELAY(0)
	)async_fsmc_sram_u(
		.aclk(pll0_clk_out),
		.aresetn(pll0_locked),
		
		.fsmc_nex(fsmc_cs),
		.fsmc_nwe(fsmc_wr),
		.fsmc_noe(fsmc_rd),
		.fsmc_nbl(fsmc_nbl),
		.fsmc_da_i(fsmc_da_i),
		.fsmc_da_o(fsmc_da_o),
		.fsmc_da_t(fsmc_da_t),
		
		.sram_clk(sram_clk),
		.sram_en(sram_en),
		.sram_wen(sram_wen),
		.sram_addr(sram_addr),
		.sram_din(sram_din),
		.sram_dout(sram_dout)
	);
	
	/** SRAM **/
	bram_single_port #(
		.style("HIGH_PERFORMANCE"),
		.rw_mode("read_first"),
		.mem_width(8),
		.mem_depth(1024),
		.INIT_FILE("no_init"),
		.byte_write_mode("false"),
		.simulation_delay(0)
	)sram_u0(
		.clk(sram_clk),
		
		.en(sram_en),
		.wen(sram_wen[0]),
		.addr(sram_addr[9:0]),
		.din(sram_din[7:0]),
		.dout(sram_dout[7:0])
	);
	bram_single_port #(
		.style("HIGH_PERFORMANCE"),
		.rw_mode("read_first"),
		.mem_width(8),
		.mem_depth(1024),
		.INIT_FILE("no_init"),
		.byte_write_mode("false"),
		.simulation_delay(0)
	)sram_u1(
		.clk(sram_clk),
		
		.en(sram_en),
		.wen(sram_wen[1]),
		.addr(sram_addr[9:0]),
		.din(sram_din[15:8]),
		.dout(sram_dout[15:8])
	);
	
endmodule
