`timescale 1ns / 1ns

module tb(
    );
    reg clk_t, intr_t, rst_n_t;
    reg [7:0] data_ip_tb;
    wire [7:0] adc_data_conv_tb;
    wire cs_n_t, wr_n_t, rd_n_t, adc_clk_tb;
    
    always #5 clk_t = ~clk_t;
    initial begin
        data_ip_tb = 8'b0000_1010;
        clk_t = 0;
        rst_n_t = 1;
        intr_t = 1;
        #10
         rst_n_t = 0;
        #100000
        intr_t = 0;
        #10500
        intr_t = 1;
    end
    ADC uut1(clk_t, intr_t, rst_n_t, data_ip_tb, cs_n_t, rd_n_t, wr_n_t, adc_clk_tb, adc_data_conv_tb);
endmodule