`timescale 1ns / 1ps

module baud_generator(
    input PCLK,
    input PRESET_n,
    input [1:0] spi_mode_i,
    input spiswai_i,
    input [2:0]sppr_i,
    input [2:0]spr_i,
    input cpol_i,
    input cpha_i,
    input ss_i,
    output reg sclk_o,
    output reg miso_receive_sclk_o,       //rising edge   (a~^b)
    output reg miso_receive_sclk0_o,     //falling edge   (a^b)
    output reg mosi_send_sclk_o,         // rising edge   (a~^b)
    output reg mosi_send_sclk0_o,        // falling edge   (a^b)
    output [11:0] BaudRateDivisor_o
);
    wire pre_sclk_s, spi_active;
    reg [11:0] count_s;
    wire [11:0] BaudRateDivisor_Intermediate, half_cycle;
    reg sclk_d;                        //internal reg to keep delayed sclk for div=2;
    reg cpol_latched, ss_previous;
    wire ss_rising,ss_falling;
    reg flag_rise_fall=0;



    assign pre_sclk_s = cpol_i;  //cpol_latched;
    //assign ss_rising  = !ss_previous && ss_i;  //if ss was 0 and now ss is 1 that is rising edge
    //assign ss_falling = ss_previous && !ss_i;

    assign BaudRateDivisor_Intermediate = ((sppr_i + 1)<<(spr_i+1));
    assign BaudRateDivisor_o = (BaudRateDivisor_Intermediate <= 12'd2)? 12'd2 : BaudRateDivisor_Intermediate;
    assign half_cycle = BaudRateDivisor_o >> 1;     // divide by 2

    assign spi_active = (~ss_i) &&                         // if ss is low and mode is run or wait with spiswai low
                        ((spi_mode_i == 2'b00) || 
                        ((spi_mode_i == 2'b01) && ~spiswai_i));   //Condition for spi to work



   /* always @(posedge PCLK or negedge PRESET_n)begin:cpol_and_ss_prev
        if(~PRESET_n)begin
            cpol_latched <= cpol_i;     //modified
            ss_previous <= 1'b1;       //modi
        end else begin 
            if(ss_rising || ss_falling)begin
                cpol_latched <= cpol_i;
                flag_rise_fall <= 1;
            end else if(flag_rise_fall)begin
                flag_rise_fall <= 0;
            end else begin
            ss_previous <= ss_i;
            end
        end
    end  */


    
    /*always @(posedge PCLK or negedge PRESET_n)begin: SPI_clock
        if(~PRESET_n)begin
            count_s <= 0;
            sclk_o <= cpol_latched;
        end else if(ss_rising)begin
            //sclk_o <= cpol_i;
            sclk_o <= cpol_latched;
            count_s <= 0;
        end else if(ss_i) begin
            sclk_o <= pre_sclk_s;
            count_s <= 0;
        end else if(spi_active) begin    // run = 00, wait = 01, stop = 10, reserve == 11
                    if(count_s == (half_cycle - 1))begin
                        sclk_o <= ~sclk_o;
                        count_s <= 0;
                    end else
                        count_s <= count_s + 1;
        end 
        
    end  */

    ///////////////////////
    always @(posedge PCLK or negedge PRESET_n)begin: SPI_clock
        if(~PRESET_n || ss_i || !spi_active)begin
            count_s <= 0;
            sclk_o <= pre_sclk_s;
        end else if(spi_active) begin    // run = 00, wait = 01, stop = 10, reserve == 11
                    if(count_s == (half_cycle - 1))begin
                        sclk_o <= ~sclk_o;
                        count_s <= 0;
                    end else
                        count_s <= count_s + 1;
        end 
        
    end


    ///////////////////////


    always @(posedge PCLK or negedge PRESET_n) begin: DIV_2
        if(~PRESET_n)begin
            sclk_d <= pre_sclk_s;
        end else
        sclk_d <= sclk_o;   //sclk_d is a delayed clock running once cycle late
    end


//------------------------------------------------------------------
////////////////  Sample edge(Miso_receive_sclk) = decided by CPHA + CPOL
////////////////  Shift edge(mosi_send_sclk) = always the opposite edge
//--------------------------------------------------------------------


    always @(posedge PCLK or negedge PRESET_n) begin : MISO_Flags  //decided by CPHA + CPOL
        if(~PRESET_n)begin
            miso_receive_sclk_o  <= 0;
            miso_receive_sclk0_o <= 0;
        end else begin

            miso_receive_sclk_o  <= 0;
            miso_receive_sclk0_o <= 0;

            if(cpol_i ^ cpha_i)begin     //falling edge
                if(spi_active && sclk_o && (count_s == (half_cycle-1)) )     //sclk_o = 1 so next edge falling
                            miso_receive_sclk0_o <= 1;

            end else if(cpol_i ~^ cpha_i)begin   //Rising edge
                if(spi_active && ~sclk_o && (count_s == (half_cycle-1)))     //sclk_o = 0 next edge rising
                            miso_receive_sclk_o <= 1;
            end

        end
    end


/*
    always @(posedge PCLK or negedge PRESET_n) begin : MOSI_Flags    //always the opposite edge of edge decided by CPHA + CPOL
        if(~PRESET_n)begin
            mosi_send_sclk_o  <= 0;
            mosi_send_sclk0_o <= 0;
        end else begin
            
            mosi_send_sclk_o  <= 0;
            mosi_send_sclk0_o <= 0;

            if(cpol_latched ^ cpha_i) begin   //falling edge

                if(BaudRateDivisor_o == 2)begin                                //if DIV=2
                    if(spi_active && sclk_d) begin
                        mosi_send_sclk0_o <= 1;
                    end
                end else if(spi_active && sclk_o && (count_s == (half_cycle-2))) begin          //if DIV > 2
                        mosi_send_sclk0_o <= 1;
                end

            end else if(cpol_latched ~^ cpha_i) begin    //rising edge

                if(BaudRateDivisor_o == 2)begin                                //if DIV=2
                    if(spi_active && ~sclk_d)
                        mosi_send_sclk_o <= 1;
                end else if(spi_active && ~sclk_o && (count_s == (half_cycle-2))) begin
                            mosi_send_sclk_o <= 1;
                end

        end

    end

    end    */



    //------------------------------------------------------
always @(posedge PCLK or negedge PRESET_n) begin : MOSI_Flags    //always the opposite edge of edge decided by CPHA + CPOL
        if(~PRESET_n)begin
            mosi_send_sclk_o  <= 0;
            mosi_send_sclk0_o <= 0;
        end else begin
            
            mosi_send_sclk_o  <= 0;
            mosi_send_sclk0_o <= 0;

           /* if(cpol_latched ^ cpha_i) begin   //falling edge
                if(cpha_i == 1)begin
                    if(BaudRateDivisor_o == 2)begin                                //if DIV=2
                        if(spi_active && ~sclk_o) begin
                            mosi_send_sclk0_o <= 1;
                        end
                    end else if(spi_active && ~sclk_o && (count_s == (half_cycle-2))) begin          //if DIV > 2
                            mosi_send_sclk0_o <= 1;
                    end
                end else begin
                if(BaudRateDivisor_o == 2)begin                                //if DIV=2
                    if(spi_active && ~sclk_o) begin
                        mosi_send_sclk0_o <= 1;
                    end
                end else if(spi_active && sclk_o && (count_s == (half_cycle-2))) begin          //if DIV > 2
                        mosi_send_sclk0_o <= 1;
                end

                end  */

            if(cpol_i ^ cpha_i) begin   //falling edge
                    if(BaudRateDivisor_o == 2)begin                                //if DIV=2
                        if(spi_active && ~sclk_o) begin
                            mosi_send_sclk0_o <= 1;
                        end
                    end else if(spi_active && ~sclk_o && (count_s == (half_cycle-2))) begin          //if DIV > 2
                            mosi_send_sclk0_o <= 1;
                    end

            end else if(cpol_i ~^ cpha_i) begin    //rising edge

                if(BaudRateDivisor_o == 2)begin                                //if DIV=2
                    if(spi_active && sclk_o)
                        mosi_send_sclk_o <= 1;
                end else if(spi_active && sclk_o && (count_s == (half_cycle-2))) begin
                            mosi_send_sclk_o <= 1;
                end

        end

    end

    end

    //---------------------------------------------------





endmodule