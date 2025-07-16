`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ganshyam
// 
// Create Date: 21.04.2025 11:51:35
// Design Name: 
// Module Name: ADC
// Project Name: ADCinterfacing with FPGA
// Target Devices: Artix-7 series FPGA (Digilent Basys 3)
// Tool Versions: 
// Description: Controlling the ADC IC 0804 to continuously acquire the 8 bit digital data
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ADC(
	input i_clk_100MHz, i_intr_n, i_reset,
	input [7:0] i_adc_data,
	output i_cs_n, i_rd_n, i_wr_n, 
	output reg o_adc_clk_1MHz,
	output [7:0] o_adc_data
);
	parameter S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5, S6 = 6;
	reg [7:0] r_adc_data;
	reg [2:0] r_state, r_next_state;
	reg [$clog2(15)-1 : 0] r_counter0;
	reg [$clog2(1300)-1 : 0] r_counter1;
	reg [$clog2(50)-1 : 0] r_counter_clk;
	wire w_counter0_en, w_counter1_en;
//////////////////////////FSM Logic/////////////////////////	
	always @(*) begin
		case(r_state)
			S0: r_next_state = S1;
			S1: r_next_state = (r_counter0 == 11) ? S2 : S1;
			S2: r_next_state = (r_counter0 == 14) ? S3 : S2;
			S3: r_next_state = (~i_intr_n) ? S4 : S3;
			S4: r_next_state = (r_counter1 == 999) ? S5 : S4;
			S5: r_next_state = (r_counter1 == 1099) ? S6 : S5;
			S6: r_next_state = (r_counter1 == 1299) ? S0 : S6;
			default: r_next_state = S0;
		endcase
	end
	
	always @(posedge i_clk_100MHz) begin
		if(i_reset)
			r_state <= S0;
		else
			r_state <= r_next_state;
	end
////////////////////FSM Counters///////////////////////////	
	always @(posedge i_clk_100MHz) begin
		if(w_counter0_en)
			r_counter0 <= r_counter0 + 1'b1;
		else
			r_counter0 <= 0;
		if(w_counter1_en)
			r_counter1 <= r_counter1 + 1'b1;
		else
			r_counter1 <= 0;
	end
///////////////////Data Sampling to internal register/////////////
	always @(posedge i_clk_100MHz) begin
		if(r_counter1 == 1029)
			r_adc_dataadc_data <= i_adc_data;
		else
			r_adc_data <= r_adc_data;
	end
	////////////////////ADC CLK Generator////////////////////////
	always @(posedge i_clk_100MHz) begin
	   if(i_reset) begin
	       r_counter_clk <= 0;
	       o_adc_clk_1MHz <= 0;
	   end
	   else if (r_counter_clk == 49) begin
	       o_adc_clk_1MHz <= ~o_adc_clk_1MHz;      
	       r_counter_clk <= 0;
	   end
	   else
	       r_counter_clk <= r_counter_clk + 1'b1;
	end
/////////////////////////FSM OPs////////////////////////////////////////////	
	assign i_cs_n = (r_state == S0) | (r_state == S3) | (r_state == S6);
	assign i_wr_n = (r_state == S0) | (r_state == S2) | (r_state == S3) | (r_state == S4) | (r_state == S5) | (r_state == S6);
	assign i_rd_n = (r_state == S0) | (r_state == S1) | (r_state == S2) | (r_state == S3) | (r_state == S4) | (r_state == S6);
	assign w_counter1_en = (r_state == S4) | (r_state == S5) | (r_state == S6);
	assign w_counter0_en = (r_state == S1) | (r_state == S2);
	
	assign o_adc_data = adc_data;
endmodule