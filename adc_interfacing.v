`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ganshyam
// 
// Create Date: 21.04.2025 11:51:35
// Design Name: 
// Module Name: exp
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module ADC(
	input clk_100MHz, intr_n, reset,
	input [7:0] data_ip,
	output cs_n, rd_n, wr_n, 
	output reg adc_clk_1MHz,
	output [7:0] adc_data_conv
);
	parameter S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5, S6 = 6;
	reg [7:0] adc_data;
	reg [2:0] state, next_state;
	reg [$clog2(15)-1 : 0] counter0;
	reg [$clog2(1300)-1 : 0] counter1;
	reg [$clog2(50)-1 : 0] counter_clk;
	wire counter0_en, counter1_en;
//////////////////////////FSM Logic/////////////////////////	
	always @(*) begin
		case(state)
			S0: next_state = S1;
			S1: next_state = (counter0 == 11) ? S2 : S1;
			S2: next_state = (counter0 == 14) ? S3 : S2;
			S3: next_state = (~intr_n) ? S4 : S3;
			S4: next_state = (counter1 == 999) ? S5 : S4;
			S5: next_state = (counter1 == 1099) ? S6 : S5;
			S6: next_state = (counter1 == 1299) ? S0 : S6;
			default: next_state = S0;
		endcase
	end
	
	always @(posedge clk_100MHz) begin
		if(reset)
			state <= S0;
		else
			state <= next_state;
	end
////////////////////FSM Counters///////////////////////////	
	always @(posedge clk_100MHz) begin
		if(counter0_en)
			counter0 <= counter0 + 1'b1;
		else
			counter0 <= 0;
		if(counter1_en)
			counter1 <= counter1 + 1'b1;
		else
			counter1 <= 0;
	end
///////////////////Data Sampling to internal register/////////////
	always @(posedge clk_100MHz) begin
		if(counter1 == 1029)
			adc_data <= data_ip;
		else
			adc_data <= adc_data;
	end
	////////////////////ADC CLK Generator////////////////////////
	always @(posedge clk_100MHz) begin
	   if(reset) begin
	       counter_clk <= 0;
	       adc_clk_1MHz <= 0;
	   end
	   else if (counter_clk == 49) begin
	       adc_clk_1MHz <= ~adc_clk_1MHz;      
	       counter_clk <= 0;
	   end
	   else
	       counter_clk <= counter_clk + 1'b1;
	end
/////////////////////////FSM OPs////////////////////////////////////////////	
	assign cs_n = (state == S0) | (state == S3) | (state == S6);
	assign wr_n = (state == S0) | (state == S2) | (state == S3) | (state == S4) | (state == S5) | (state == S6);
	assign rd_n = (state == S0) | (state == S1) | (state == S2) | (state == S3) | (state == S4) | (state == S6);
	assign counter1_en = (state == S4) | (state == S5) | (state == S6);
	assign counter0_en = (state == S1) | (state == S2);
	
	assign adc_data_conv = adc_data;
endmodule