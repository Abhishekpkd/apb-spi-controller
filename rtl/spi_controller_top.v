`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.03.2026 11:38:35
// Design Name: 
// Module Name: spi_controller_top
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


module spi_controller_top(
//////////////////apb_slave
    input PCLK,
    input PRESET_n,
    input [2:0]PADDR_i,
    input PWRITE_i,
    input PSEL_i,
    input PENABLE_i,
    input [7:0] PWDATA_i,
    input miso_i,   // connected to pheriferal receiving serially //miso_i and mosi_o are 2 1bit serial line to phereferal // receive in internal temp veriable once all data received(8bit) will get receive_data_i signal then output it through data_miso_o
    output mosi_o,
    output sclk_o,
    output ss_o,
    output [7:0]PRDATA_o,
    output PREADY_o,
    output PSLVERR_o,
    output spi_interrupt_request_o
    );

    wire cpol_o, cpha_o, receive_data_o, tip_o, send_data_o, lsbfe_o;
    wire mstr_o, spiswai_o;
    wire miso_receive_sclk_o,miso_receive_sclk0_o,mosi_send_sclk_o,mosi_send_sclk0_o;
    wire [1:0]spi_mode_o;
    wire [2:0] sppr_o,spr_o;
    wire [7:0] mosi_data_o, data_miso_o;
    wire [11:0] BaudRateDivisor_o;

    baud_generator inst_baud(.PCLK(PCLK), .PRESET_n(PRESET_n), .spi_mode_i(spi_mode_o),
     .spiswai_i(spiswai_o), .sppr_i(sppr_o), .spr_i(spr_o), .cpol_i(cpol_o),
      .cpha_i(cpha_o), .ss_i(ss_o), .sclk_o(sclk_o), .miso_receive_sclk_o(miso_receive_sclk_o),
      .miso_receive_sclk0_o(miso_receive_sclk0_o), .mosi_send_sclk_o(mosi_send_sclk_o),
       .mosi_send_sclk0_o(mosi_send_sclk0_o), .BaudRateDivisor_o(BaudRateDivisor_o));

    apb_slave inst_slave(.PCLK(PCLK), .PRESET_n(PRESET_n), .PADDR_i(PADDR_i),
     .PWRITE_i(PWRITE_i), .PSEL_i(PSEL_i), .PENABLE_i(PENABLE_i), .PWDATA_i(PWDATA_i),
      .ss_i(ss_o), .miso_data_i(data_miso_o), .receive_data_i(receive_data_o),
       .tip_i(tip_o),  .PRDATA_o(PRDATA_o), .mstr_o(mstr_o), .cpol_o(cpol_o),
        .cpha_o(cpha_o), .lsbfe_o(lsbfe_o), .spiswai_o(spiswai_o), .sppr_o(sppr_o),
         .spr_o(spr_o), .spi_interrupt_request_o(spi_interrupt_request_o),
          .PREADY_o(PREADY_o), .PSLVERR_o(PSLVERR_o),.send_data_o(send_data_o),
          .mosi_data_o(mosi_data_o), .spi_mode_o(spi_mode_o));

    spi_shifter inst_shifter(.PCLK(PCLK), .PRESET_n(PRESET_n), .ss_i(ss_o), 
    .send_data_i(send_data_o), .lsbfe_i(lsbfe_o), .cpha_i(cpha_o), .cpol_i(cpol_o),
     .miso_receive_sclk_i(miso_receive_sclk_o),.miso_receive_sclk0_i(miso_receive_sclk0_o),
      .mosi_send_sclk_i(mosi_send_sclk_o), .mosi_send_sclk0_i(mosi_send_sclk0_o),
       .data_mosi_i(mosi_data_o), .miso_i(miso_i), .receive_data_i(receive_data_o),
        .mosi_o(mosi_o), .data_miso_o(data_miso_o));

    spi_slave_select inst_slave_sel(.PCLK(PCLK), .PRESET_n(PRESET_n), .mstr_i(mstr_o),
     .spiswai_i(spiswai_o), .spi_mode_i(spi_mode_o), .send_data_i(send_data_o),
      .BaudRateDivisor_i(BaudRateDivisor_o), .receive_data_o(receive_data_o),
       .ss_o(ss_o), .tip_o(tip_o));

endmodule
