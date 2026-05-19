`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.03.2026 09:35:09
// Design Name: 
// Module Name: spi_slave_control
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


module spi_slave_select_tb();
reg PCLK;
reg PRESET_n;   //activelow
reg mstr_i;
reg spiswai_i;
reg [1:0]spi_mode_i;
reg send_data_i;
reg [11:0]BaudRateDivisor_i;
wire receive_data_o;
wire ss_o;
wire tip_o;

spi_slave_select DUT(PCLK, PRESET_n, mstr_i, spiswai_i, spi_mode_i, send_data_i,
BaudRateDivisor_i,receive_data_o,ss_o,tip_o);

always #20 PCLK = ~PCLK;
initial begin
     PCLK              = 0;
     mstr_i            = 1;
     spiswai_i         = 0;
     spi_mode_i        = 2'b00;
     PRESET_n          = 1;
     send_data_i       = 0;
     BaudRateDivisor_i = 32;
end

task resetDUT();
begin
PRESET_n = 0;
repeat(5) @(posedge PCLK);
PRESET_n = 1;
end
endtask

task run_mode(input [11:0]div);
begin
@(negedge PCLK);
spi_mode_i = 2'b00;
spiswai_i  = 0;
BaudRateDivisor_i = div;
send_data_i = 1;
@(negedge PCLK);
send_data_i = 0;
end
endtask

task wait_with_spiswai0(input [11:0]div);
begin
@(negedge PCLK);
spi_mode_i = 2'b01;
spiswai_i  = 0;
BaudRateDivisor_i = div;
send_data_i = 1;
@(negedge PCLK);
send_data_i = 0;
end
endtask

task wait_with_spiswai1(input [11:0]div);
begin
@(negedge PCLK);
spi_mode_i = 2'b01;
spiswai_i  = 1;
BaudRateDivisor_i = div;
send_data_i = 1;
@(negedge PCLK);
send_data_i = 0;
end
endtask


initial begin
    #10;
    resetDUT();
    run_mode(12'd2);
     #300;
    repeat(20) @(posedge PCLK);
    run_mode(12'd8);
    repeat(20) @(posedge PCLK);
    #600;
    wait_with_spiswai0(12'd4);
    repeat(20) @(posedge PCLK);
    #200;
    wait_with_spiswai1(12'd32);
    repeat(20) @(posedge PCLK);
    #200;
    run_mode(12'd8);
    #40;
    send_data_i = 1;  // should be ignored
    @(posedge PCLK);
    send_data_i = 0;


#3000;
$finish;
end


initial begin
    $monitor("t=%0t | ss=%b tip=%b send=%b mode=%b swi=%b div=%0d receive_data_o=%b, count_s=%0d",
        $time, ss_o, tip_o, send_data_i, spi_mode_i, spiswai_i, BaudRateDivisor_i, receive_data_o, DUT.count_s);
end




endmodule
