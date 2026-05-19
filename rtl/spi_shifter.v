`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.03.2026 21:58:56
// Design Name: 
// Module Name: spi_shifter
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


module spi_shifter(
    input PCLK,
    input PRESET_n,
    input ss_i,
    input send_data_i,
    input lsbfe_i,
    input cpha_i,
    input cpol_i,
    input miso_receive_sclk_i,
    input miso_receive_sclk0_i,
    input mosi_send_sclk_i,
    input mosi_send_sclk0_i,
    input [7:0] data_mosi_i,   //this is parallel in and serial out through mosi_o this is coming from data register for serial output keep in shift register for transmission (send_data_i should be high)
    input miso_i,   // connected to pheriferal receiving serially //miso_i and mosi_o are 2 1bit serial line to phereferal // receive in internal temp veriable once all data received(8bit) will get receive_data_i signal then output it through data_miso_o
    input receive_data_i,
    output reg mosi_o,   //connected to pheriferal send serially
    output reg [7:0] data_miso_o  //this is serial in parallel out goes to data register //during receiving(receive_data_i) this is going to data register
    );

reg [7:0]shift_register, temp_reg;
reg [2:0] count0,count1;
reg send_data_i_delayed;
//reg receive_flag;
 
always @(posedge PCLK or negedge PRESET_n)begin:Data_register
    if(~PRESET_n)begin
        shift_register <= 0;
        data_miso_o <= 0;
end else begin 

    if(send_data_i)begin
        send_data_i_delayed <= 1;
    end

    if(send_data_i_delayed)begin
        shift_register <= data_mosi_i;
        send_data_i_delayed <= 0;
    end

    if(receive_data_i) begin
        data_miso_o <= temp_reg; 
    end

    end
end

always @(posedge PCLK or negedge PRESET_n)begin:MOSI
    if(~PRESET_n)begin
       mosi_o <= 1'b0;
       count0 <= 3'b000; 
    end else if(~ss_i)begin
        if(cpha_i ^ cpol_i)begin    //falling edge
            if(lsbfe_i)begin
                if((count0 < 3'd7) && mosi_send_sclk0_i)begin
                    mosi_o <= shift_register[0];
                    shift_register <= (shift_register >> 1);
                    count0 <= count0 + 1;
                end else if((count0 == 3'd7) && mosi_send_sclk0_i)begin
                    mosi_o <= shift_register[0];
                    shift_register <= (shift_register >> 1);
                    count0 <= 3'b000;
                end
            end else begin 
                if((count0 <3'd7) && mosi_send_sclk0_i)begin
                    mosi_o <= shift_register[7];
                    shift_register <= (shift_register << 1);
                    count0 <= count0 + 1;
                end else if((count0 == 3'd7) && mosi_send_sclk0_i)begin
                    mosi_o <= shift_register[7];
                    shift_register <= (shift_register << 1);
                    count0 <= 3'b000;
                end
            end
        end else if(cpha_i ~^ cpol_i) begin    //rising edge
            if(lsbfe_i)begin
                if((count0 < 3'd7) && mosi_send_sclk_i)begin
                    mosi_o <= shift_register[0];
                    shift_register <= (shift_register >> 1);
                    count0 <= count0 +1;
                end else if((count0 == 3'd7) && mosi_send_sclk_i)begin
                    mosi_o <= shift_register[0];
                    shift_register <= (shift_register >> 1);
                    count0 <= 3'b000;
                end
            end else begin
                if((count0 < 3'd7) && mosi_send_sclk_i)begin
                    mosi_o <= shift_register[7];
                    shift_register <= (shift_register << 1);
                    count0 <= count0 + 1;
                end else if((count0 == 3'd7) && mosi_send_sclk_i)begin
                    mosi_o <= shift_register[7];
                    shift_register <= (shift_register << 1);
                    count0 <= 3'b000;
                end
            end

        end
    end else begin
        count0 <= 3'b000;
    end

end

always @(posedge PCLK or negedge PRESET_n)begin:MISO
    if(~PRESET_n)begin
        count1 <= 3'b000;
        temp_reg <= 0;
    end else if(~ss_i)begin
        if(cpha_i ^ cpol_i)begin       //falling edge
            if(~lsbfe_i)begin
                if(count1 < 3'd7 && miso_receive_sclk0_i)begin
                    temp_reg<= {temp_reg[6:0],miso_i};
                    count1 <= count1 + 1;
                end else if(count1 == 3'd7 && miso_receive_sclk0_i)begin
                    temp_reg<= {temp_reg[6:0],miso_i};
                    count1 <= 3'b000;
                end
            end else begin
                if((count1 < 3'd7) && miso_receive_sclk0_i)begin
                    temp_reg <= {miso_i,temp_reg[7:1]};
                    count1 <= count1 + 1;
                end else if((count1 == 3'd7) && miso_receive_sclk0_i)begin
                    temp_reg <= {miso_i,temp_reg[7:1]};
                    count1 <= 3'b000;
                end
            end
        end else if(cpha_i ~^ cpol_i)begin     //rising  edge
            if(~lsbfe_i)begin
                if((count1 < 3'd7) && miso_receive_sclk_i)begin
                    temp_reg <= {temp_reg[6:0],miso_i};
                    count1 <= count1 +1;
                end else if((count1 == 3'd7) && miso_receive_sclk_i)begin
                    temp_reg <= {temp_reg[6:0],miso_i};
                    count1 <= 3'b000;
                end
            end else begin
                if ((count1 < 3'd7) && miso_receive_sclk_i)begin
                    temp_reg <= {miso_i,temp_reg[7:1]};
                    count1 <= count1 + 1;
                end else if ((count1 == 3'd7) && miso_receive_sclk_i)begin
                    temp_reg <= {miso_i,temp_reg[7:1]};
                    count1 <= 3'b000;
                end
            end

        end
    end else begin
        count1 <= 3'b000;
    end
end



endmodule

