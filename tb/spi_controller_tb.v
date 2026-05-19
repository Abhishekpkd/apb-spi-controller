`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.04.2026 10:31:07
// Design Name: 
// Module Name: spi_controller_tb
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


module spi_controller_top_tb();

    reg PCLK;
    reg PRESET_n;
    reg [2:0] PADDR_i;
    reg PWRITE_i;
    reg PSEL_i;
    reg PENABLE_i;
    reg [7:0] PWDATA_i;
    reg miso_i;   // connected to pheriferal receiving serially //miso_i and mosi_o are 2 1bit serial line to phereferal // receive in internal temp veriable once all data received(8bit) will get receive_data_i signal then output it through data_miso_o
   
    wire mosi_o;
    wire sclk_o;
    wire ss_o;
    wire [7:0] PRDATA_o;
    wire PREADY_o;
    wire PSLVERR_o;
    wire spi_interrupt_request_o;

spi_controller_top DUT( PCLK, PRESET_n, PADDR_i, PWRITE_i, PSEL_i, PENABLE_i, PWDATA_i,
miso_i, mosi_o, sclk_o, ss_o, PRDATA_o, PREADY_o, PSLVERR_o, spi_interrupt_request_o);

parameter Add_SPI_CR1 =3'b000, Add_SPI_CR2=3'b001, Add_SPI_BR = 3'b010, Add_SPI_SR = 3'b011, Add_SPI_DR=3'b101;
event pereferal;
reg [2:0]count=0;
reg [7:0]pereferal_slave=8'b10100011;
reg [7:0] spi_dr_data, spi_cr1_data;
event risingPereferal00,risingPereferal11, fallingPereferal01,fallingPereferal10;
integer count00,count01,count10,count11, countmosi;

always #20 PCLK = ~PCLK;

initial begin
PCLK       = 0 ;
end




//--------------------------------------------------------------------------------------------------------------------PEREFERAL 

always  begin:rising_cpol0cpha0
    @(risingPereferal00);
    wait(~ss_o);
    if(spi_cr1_data[0]==1)begin
        for(count00=0;count00<8;count00=count00+1) begin
            miso_i = pereferal_slave[count00];
            @(negedge sclk_o);  // wait for negedge so fresh data available at negedge
        end 
    end else begin
        for(count00=7;count00>=0;count00=count00-1) begin
            miso_i = pereferal_slave[count00];
            @(negedge sclk_o);  // wait for negedge so fresh data available at negedge
        end 
    end
end


always  begin:falling_cpol0cpha1
    @(fallingPereferal01);
    wait(~ss_o);
    if(spi_cr1_data[0]==1)begin
        for(count01=0;count01<8;count01=count01+1) begin
            // wait for posedge so fresh data available at negedge
            @(posedge sclk_o); 
            miso_i = pereferal_slave[count01];   //8'b10100011
        end
    end else begin
        for(count01=7;count01>=0;count01=count01-1) begin
            // wait for posedge so fresh data available at negedge
            @(posedge sclk_o); 
            miso_i = pereferal_slave[count01];
        end
    end
end


always  begin:falling_cpol1cpha0
    @(fallingPereferal10);
    wait(~ss_o);
    if(spi_cr1_data[0]==1)begin
        for(count10=0;count10<8;count10=count10+1) begin
            miso_i = pereferal_slave[count10];
            @(posedge sclk_o);  // wait for posedge so fresh data available at negedge
        end 
    end else begin
        for(count10=7;count10>=0;count10=count10-1) begin
            miso_i = pereferal_slave[count10];
            @(posedge sclk_o);  // wait for posedge so fresh data available at negedge
        end 
    end
end


always  begin:rising_cpol1cpha1
    //count11=0;
    @(risingPereferal11);  
    wait(~ss_o);
    if(spi_cr1_data[0]==1)begin
        for(count11=0;count11<8;count11=count11+1) begin
            //wait for negedge so fresh data is available on posedge to sample 
            @(negedge sclk_o);
            miso_i = pereferal_slave[count11];
            @(posedge sclk_o);
        end
    end else begin
        for(count11=7;count11 >= 0;count11=count11-1) begin
            //wait for negedge so fresh data is available on posedge to sample 
            @(negedge sclk_o);
            miso_i = pereferal_slave[count11];
            @(posedge sclk_o);
        end
    end
end



always @(negedge ss_o) begin
    case ({spi_cr1_data[3], spi_cr1_data[2]})
        2'b00: ->risingPereferal00;
        2'b01: ->fallingPereferal01;
        2'b10: ->fallingPereferal10;
        2'b11: ->risingPereferal11;
    endcase
end


//-----------------------------------------------------------------------------------------------------------------------------------

                                         
reg [7:0] mosi_val;
integer count_mosi;

always @(posedge PCLK or negedge PRESET_n) begin
    if(!PRESET_n) begin
        mosi_val   <= 0;
        count_mosi <= 0;
    end else begin
        if(spi_cr1_data[3] ^spi_cr1_data[2]) begin

            if(!ss_o && DUT.inst_baud.mosi_send_sclk0_o && count_mosi < 8) begin
                @(negedge PCLK);  //delay to let data stable
                if(spi_cr1_data[0] == 0) begin
                    // MSB first
                    mosi_val <= {mosi_val[6:0], mosi_o};
                end else begin
                    // LSB first
                    mosi_val <= {mosi_o, mosi_val[7:1]};
                end
                count_mosi <= count_mosi + 1;
            end
            
            if(count_mosi >= 8) begin
                $display("TIME=%t | lsbfe=%b | MOSI=%h", $time,spi_cr1_data[0], mosi_val);
                mosi_val = 8'b0;
                count_mosi <= 0;
            end

        end else if(~(spi_cr1_data[3] ^spi_cr1_data[2]))begin
            if(!ss_o && DUT.inst_baud.mosi_send_sclk_o && count_mosi < 8) begin
                @(negedge PCLK); 
                if(spi_cr1_data[0] == 0) begin
                    // MSB first
                    mosi_val <= {mosi_val[6:0], mosi_o};
                end else begin
                    // LSB first
                    mosi_val <= {mosi_o, mosi_val[7:1]};
                end
                count_mosi <= count_mosi + 1;
            end
            
            if(count_mosi >= 8) begin
                $display("TIME=%t | lsbfe=%b | MOSI=%h", $time,spi_cr1_data[0], mosi_val);
                mosi_val = 8'b0;
                count_mosi <= 0;
            end

        end

    end
end



//---------------------------------------------------------------


// APB READ & WRITE ------------------------------------------------------------------------

task apb_write(input [2:0] address_w,input [7:0]data, input last);
    begin
        @(negedge PCLK);
            PADDR_i  = address_w;
            PWRITE_i = 1;
            PSEL_i   = 1;
            PWDATA_i = data;
            $display("TIME %t | apb_write | Address=%b | data=%h",$time,address_w,data);
            PENABLE_i = 0;
        @(negedge PCLK);
            PENABLE_i = 1;
            wait(PREADY_o);
        @(negedge PCLK);
            PENABLE_i = 0;
            if(last)
                PSEL_i = 0;   // only drop after final transfer
    end
endtask


task apb_read(input [2:0]address_r);
    begin
        @(negedge PCLK);
            PADDR_i  = address_r;
            PWRITE_i = 0;
            PSEL_i   = 1;
            PENABLE_i = 0;
        @(negedge PCLK);
            PENABLE_i = 1;
            wait(PREADY_o);
            @(posedge PCLK);
            $display("TIME %t | READ ADDR=%b DATA=%b",$time, address_r, PRDATA_o);
            if(address_r === Add_SPI_DR ) begin
               // wait(receive_data_i);
                if(PRDATA_o !== pereferal_slave)begin  //8'b10100011
                    $display("TIME %t|ERROR | pereferal_slave=%h | PRDATA_o=%h",$time, pereferal_slave, PRDATA_o);
                end else begin
                    $display("TIME %t|PASS | pereferal_slave=%h | PRDATA_o=%h",$time, pereferal_slave, PRDATA_o);
                end
            end
        @(negedge PCLK);
            PENABLE_i = 0;
            PSEL_i = 0;
    end
endtask

//--------------------------------------------------------------------------------------------------------------


// RESET---------------------------------------------

initial begin
    PRESET_n = 0;
    repeat(3) @(posedge PCLK);
    PRESET_n = 1;
end

//----------------------------------------------------


initial begin
    #120;
    $timeformat(-9,1,"ns",8);
    @(negedge PCLK);

    //Set Control Registers --------------------------------------
    spi_cr1_data = 8'b0101_0101;
    apb_write(Add_SPI_CR1, spi_cr1_data,1); // SPE=1, MSTR=1, LSBFE=1
    apb_write(Add_SPI_CR2,  8'b0000_0000,1); // 
    apb_write(Add_SPI_BR,  8'b0000_0001,1); // baud
    //------------------------------------------------------------

    //Back to back data write -------------------------------------
    spi_dr_data = 8'hA5;    
    apb_write(Add_SPI_DR,  spi_dr_data,0);

    spi_dr_data =8'h3C;     //0011_1100   0011_1100  3c
    apb_write(Add_SPI_DR, spi_dr_data, 0); 

    spi_dr_data = 8'hF0;
    apb_write(Add_SPI_DR, spi_dr_data, 1);  // last transfer
    //--------------------------------------------------------------

    #3000;
    

    //----------------------------------------------  LSBFE=0
    spi_cr1_data = 8'b0101_0100;
    apb_write(Add_SPI_CR1, spi_cr1_data,1);  // SPE=1, MSTR=1 
    //-------------------------------------------------------

    //wait (~DUT.inst_slave_sel.tip_i);
    
    // Back to back data write-------------------------------
    spi_dr_data = 8'h6c;      
    apb_write(Add_SPI_DR,  spi_dr_data,0);
    spi_dr_data =8'h24;
    apb_write(Add_SPI_DR, spi_dr_data, 0); 
    spi_dr_data = 8'hab;
    apb_write(Add_SPI_DR, spi_dr_data, 1);  // last transfer 
    //--------------------------------------------------------

    @(negedge ss_o);
    @(posedge ss_o);

    #2000;
    $display("TIME %t | Reading now",$time);

    // Read Control Registers -----------------------------
    apb_read(Add_SPI_CR1);

    apb_read(Add_SPI_CR2);
    
    apb_read(Add_SPI_BR);

    //---------------------------------------------------
    wait(DUT.inst_slave.spif);
    apb_read(Add_SPI_SR);
    apb_read(Add_SPI_DR);
    
    wait(~DUT.inst_slave.spif);
    //-------------------------------------------------------


    pereferal_slave = 8'h19;   //Pereferal DATA

    spi_dr_data = 8'hcd;
    apb_write(Add_SPI_DR, spi_dr_data, 1);  // last transfer 
    wait(DUT.inst_slave.spif);
    apb_read(Add_SPI_SR);
    apb_read(Add_SPI_DR);
    apb_read(Add_SPI_SR);
    if (PRDATA_o[7] != 0) begin
        $display("TIME %t|ERROR | SPIF not cleared",$time);
    end else begin
        $display("TIME %t|PASS | SPIF cleared ",$time);
    end

    #4000;

    //--------------------------------------Set Control Registers
    spi_cr1_data = 8'b0101_0001;
    apb_write(Add_SPI_CR1, spi_cr1_data,1); // SPE=1, MSTR=1, LSBFE=1
    apb_write(Add_SPI_CR2,  8'b0000_0000,1); // 
    apb_write(Add_SPI_BR,  8'b0000_0001,1); // baud
    //------------------------------------------------------------

    //wait(~DUT.inst_slave.spif);

    pereferal_slave = 8'h21;   //Pereferal DATA

    spi_dr_data = 8'haf;
    apb_write(Add_SPI_DR, spi_dr_data, 1);  // last transfer 
    wait(DUT.inst_slave.spif);
    apb_read(Add_SPI_SR);
    apb_read(Add_SPI_DR);

    #5000;
    $finish;
end
endmodule

//to correct send_data_o