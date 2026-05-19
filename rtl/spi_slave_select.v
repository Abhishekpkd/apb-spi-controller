module spi_slave_select(
input PCLK,
input PRESET_n,   //activelow
input mstr_i,
input spiswai_i,
input [1:0]spi_mode_i,
input send_data_i,
input [11:0]BaudRateDivisor_i,
output reg receive_data_o,
output reg ss_o,
output tip_o
);

reg  [15:0] count_s;
wire [15:0] target_s; 
wire valid_mode;
//wire valid_BaudRate;
reg [11:0] BaudRateDivisor_latch;
// target_s = BaudRateDivisor_i * 16
// BaudRateDivisor_i is 12 bits
// multiplication by 16 (2^4) increases width by 4 bits → 12 + 4 = 16 bits

localparam  count_reset = 16'hFFFF ;

reg rcv_s;                  // internal register to trigger receive_data_o


// for BaudRateDivisor = 2, the total duration is 16 PCLK cycles,
// which corresponds to 32 PCLK edges. However, since counter increments only on the positive edge of PCLK, only need to count 16 cycles, not 32 edges.

assign target_s = (BaudRateDivisor_latch << 3)+1;     // baudrate * 8(number of bits) 
assign tip_o = ~ss_o;
//assign valid_BaudRate = (BaudRateDivisor_latch >=2);

assign valid_mode = (spi_mode_i == 2'b00 || (spi_mode_i==2'b01 && ~spiswai_i));

always @(posedge PCLK or negedge PRESET_n)begin
    if(~PRESET_n)begin
        count_s <= count_reset;
        ss_o <= 1;
        rcv_s <= 0;
        BaudRateDivisor_latch <= 0;  //2
    end else if(mstr_i )begin
        if(!valid_mode)begin
            ss_o <= 1;
            rcv_s <= 0;
            count_s <= count_reset;
        end else if(send_data_i && (count_s == count_reset) && (BaudRateDivisor_i >= 2))begin
            BaudRateDivisor_latch <= BaudRateDivisor_i;
            ss_o <= 0;
            count_s <= 0;
            rcv_s <= 0;
        end else if((count_s != count_reset) && (count_s < (target_s-1))) begin
            ss_o <= 0;
            rcv_s <= 0;
            count_s <= count_s + 1;
        end else if(count_s == (target_s-1))begin
            ss_o <= 1;
            rcv_s <= 1;
            count_s <= count_reset;
        end  else begin
            ss_o <= 1;
            rcv_s <= 0;
            count_s <= count_reset;
        end  

    end else begin
        ss_o <= 1;
        rcv_s <= 0;
        count_s <= count_reset;
    end   

end

always @(posedge PCLK or negedge PRESET_n)begin
    if(~PRESET_n)begin
        receive_data_o <= 0;
    end else
        receive_data_o <= rcv_s;

end




endmodule