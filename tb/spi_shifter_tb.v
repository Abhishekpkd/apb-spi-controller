`timescale 1ns/1ps

module spi_shifter_tb();

///////////////////////
// DUT Signals
///////////////////////
reg PCLK;      //---------- dut input
reg PRESET_n;  //---------- dut input
//reg ss_i;
reg send_data_i;  //---------- dut input
reg lsbfe_i;  //---------- dut input
reg cpha_i;  //---------- dut input
reg cpol_i;  //---------- dut input

/* reg miso_receive_sclk_i;
reg miso_receive_sclk0_i;
reg mosi_send_sclk_i;
reg mosi_send_sclk0_i;
*/

reg [7:0] data_mosi_i;  //---------- dut input
reg miso_i;  //---------- dut input  PEREFERAL
//reg receive_data_i;

wire mosi_o;           // TO PEREFERAL  OBSERVE
wire [7:0] data_miso_o;  // OBSERVE

//BAUD GENERATOR MODULE
reg [1:0] spi_mode_i;  //---------- dut input
reg spiswai_i;  //---------- dut input
reg [2:0] sppr_i;  //---------- dut input
reg [2:0] spr_i;  //---------- dut input

wire sclk_o;
wire miso_receive_sclk_o;       //rising edge   (a~^b)
wire miso_receive_sclk0_o;     //falling edge   (a^b)
wire mosi_send_sclk_o;         // rising edge   (a~^b)
wire mosi_send_sclk0_o;        // falling edge   (a^b)
wire [11:0] BaudRateDivisor_o;


//SLAVE SELECT MODULE
reg mstr_i;       //---------- dut input
//reg [11:0] BaudRateDivisor_i;

wire receive_data_o;
wire ss_o;
wire tip_o;     // not needed for testing spi_shifter module


//Testbench data
reg [7:0]perefData = 8'b1001_1010;   //  1001_1010
reg [7:0] tb_data_mosi;
//localparam tb_miso_data = 8'b1010_1001;
integer count00,count01,count10,count11, countmosi;
event risingPereferal00,risingPereferal11, fallingPereferal01,fallingPereferal10;
integer error_count = 0,j;
reg [32:0]Errtime [7:0];
wire [2:0] countval00;
//assign countval00 = (lsbfe_i)?0:7;

//assign countval00 = (lsbfe_i)?3'b0:3'b111;



///////////////////////
// DUT Instantiation
///////////////////////
spi_shifter DUT_shifter (
    .PCLK(PCLK),
    .PRESET_n(PRESET_n),
    .ss_i(ss_o),
    .send_data_i(send_data_i),
    .lsbfe_i(lsbfe_i),
    .cpha_i(cpha_i),
    .cpol_i(cpol_i),
    .miso_receive_sclk_i(miso_receive_sclk_o),
    .miso_receive_sclk0_i(miso_receive_sclk0_o),
    .mosi_send_sclk_i(mosi_send_sclk_o),
    .mosi_send_sclk0_i(mosi_send_sclk0_o),
    .data_mosi_i(data_mosi_i),
    .miso_i(miso_i),
    .receive_data_i(receive_data_o),
    .mosi_o(mosi_o),
    .data_miso_o(data_miso_o)
);

///////////////////////
// DUT Instantiation
///////////////////////

baud_generator DUT_baud(
    .PCLK(PCLK),
    .PRESET_n(PRESET_n),
    .spi_mode_i(spi_mode_i),
    .spiswai_i(spiswai_i),
    .sppr_i(sppr_i),
    .spr_i(spr_i),
    .cpol_i(cpol_i),
    .cpha_i(cpha_i),
    .ss_i(ss_o),
    .sclk_o(sclk_o),
    .miso_receive_sclk_o(miso_receive_sclk_o),
    .miso_receive_sclk0_o(miso_receive_sclk0_o),
    .mosi_send_sclk_o(mosi_send_sclk_o),
    .mosi_send_sclk0_o(mosi_send_sclk0_o),
    .BaudRateDivisor_o(BaudRateDivisor_o)
);


///////////////////////
// DUT Instantiation
///////////////////////

spi_slave_select DUT_slave_sel(
    .PCLK(PCLK),
    .PRESET_n(PRESET_n),
    .mstr_i(mstr_i),
    .spiswai_i(spiswai_i),
    .spi_mode_i(spi_mode_i),
    .send_data_i(send_data_i),
    .BaudRateDivisor_i(BaudRateDivisor_o),
    .receive_data_o(receive_data_o),
    .ss_o(ss_o),
    .tip_o(tip_o));

///////////////////////
// Clock Generation
///////////////////////
always #20 PCLK = ~PCLK;

///////////////////////
// TASKS
///////////////////////

initial begin
    PCLK = 0;
    PRESET_n = 1;
    //send_data_i = 0;
    //lsbfe_i = 0;
    //cpha_i = 1;
    //cpol_i = 1;
    //data_mosi_i = 8'h7C;
   // miso_i = 0;
    //spi_mode_i = 2'b00;
    //spiswai_i = 0;
    //sppr_i = 3'd0;
    //spr_i  = 3'd1;
    mstr_i = 1;
end

task reset_dut();
begin
PRESET_n = 0;
repeat(3) @(posedge PCLK);
PRESET_n = 1;
end
endtask

task setcpolCpha(input Cpol, Cpha);
begin
@(negedge PCLK);
cpol_i = Cpol;
cpha_i = Cpha;
@(negedge PCLK);
if (cpha_i ^ cpol_i) begin
    if(cpha_i == 0)
    ->fallingPereferal10;
    else
    ->fallingPereferal01;
end else begin
    if(cpha_i == 0)
    ->risingPereferal00;
    else
    ->risingPereferal11;
end
end
endtask

task runDUT(//input sendData_i,
input Lsbfe_i,
//input MISO_I,
input Spiswai_i,
input [7:0]Data_MOSI_i,
input [1:0]SPI_Mode_i,
input [2:0] Sppr_i,
input [2:0]Spr_i );
begin
@(negedge PCLK);
lsbfe_i = Lsbfe_i;
//miso_i  = MISO_I;
spiswai_i = Spiswai_i;
data_mosi_i = Data_MOSI_i;
spi_mode_i = SPI_Mode_i;
sppr_i = Sppr_i;
spr_i = Spr_i;
//send_data_i = sendData_i;
//@(negedge PCLK);
send_data_i = 1'b1;
repeat(2) @(negedge PCLK);
send_data_i = 1'b0;
end
endtask


/* always @(posedge miso_receive_sclk_o or posedge miso_receive_sclk0_o) begin
        miso_i <= perefData[count];
        count <= count+1;
    end */

   /* always  begin:rising_cpol0cpha0
        
        @(risingPereferal00);
        //count00 = countval00;
        count00 = (lsbfe_i)?0:7;
        wait(~ss_o);
        if(lsbfe_i==1)begin
            miso_i = perefData[count00];    // 8'b1001_1010
            count00 = count00+1; 
            for(;count00<8;count00=count00+1) begin
                @(negedge sclk_o); //wait for negedge so fresh data is available on posedge to sample 
                //$display("WE REACHED HERE miso=%b",miso_i);
                miso_i = perefData[count00];
                @(posedge sclk_o);
            end
        end else begin
            miso_i = perefData[count00];    // 8'b1001_1010
            //$display("*WE REACHED HERE miso=%b count00=%d",miso_i,count00);
            count00 = count00 - (1'b1); 
            for(;count00>=0;count00=count00-(1'b1)) begin
                @(negedge sclk_o); //wait for negedge so fresh data is available on posedge to sample 
                miso_i = perefData[count00];
                //$display("WE REACHED HERE miso=%b count00=%d",miso_i,count00);
                @(posedge sclk_o);
            end
        end
    end   */


    /////////////////////////////
    always  begin:rising_cpol0cpha0
        @(risingPereferal00);
        wait(~ss_o);
        if(lsbfe_i==1)begin
            for(count00=0;count00<8;count00=count00+1) begin
                miso_i = perefData[count00];
                //$display("WE REACHED HERE miso=%b count00=%d",miso_i,count00);
                @(negedge sclk_o);  // wait for negedge so fresh data available at negedge
            end 
        end else begin
            for(count00=7;count00>=0;count00=count00-1) begin
                miso_i = perefData[count00];
                //$display("*WE REACHED HERE miso=%b count00=%d",miso_i,count00);
                @(negedge sclk_o);  // wait for negedge so fresh data available at negedge
            end 
        end
    end

    ////////////////////////////

    
    always  begin:falling_cpol1cpha0
        @(fallingPereferal10);
        wait(~ss_o);
        if(lsbfe_i==1)begin
            for(count10=0;count10<8;count10=count10+1) begin
                miso_i = perefData[count10];
                @(posedge sclk_o);  // wait for posedge so fresh data available at negedge
            end 
        end else begin
            for(count10=7;count10>=0;count10=count10-1) begin
                miso_i = perefData[count10];
                @(posedge sclk_o);  // wait for posedge so fresh data available at negedge
            end 
        end
    end

    always  begin:rising_cpol1cpha1
        //count11=0;
        @(risingPereferal11);  
        wait(~ss_o);
        if(lsbfe_i==1)begin
        for(count11=0;count11<8;count11=count11+1) begin
            //wait for negedge so fresh data is available on posedge to sample 
            @(negedge sclk_o);
            miso_i = perefData[count11];   //8'b1001_1010
            @(posedge sclk_o);
        end
        end else begin
            for(count11=7;count11 >= 0;count11=count11-1) begin
            //wait for negedge so fresh data is available on posedge to sample 
            @(negedge sclk_o);
            miso_i = perefData[count11];   //8'b1001_1010
            @(posedge sclk_o);
        end
        end
    end

    always  begin:falling_cpol0cpha1

        @(fallingPereferal01);
        wait(~ss_o);
        if(lsbfe_i==1)begin
            for(count01=0;count01<8;count01=count01+1) begin
                // wait for posedge so fresh data available at negedge
                @(posedge sclk_o); 
                miso_i <= perefData[count01];
            end
        end else begin
            for(count01=7;count01>=0;count01=count01-1) begin
                // wait for posedge so fresh data available at negedge
                @(posedge sclk_o); 
                miso_i <= perefData[count01];
            end
        end
    end

    always begin: Self_check_mosi
        wait(~ss_o);
        if(lsbfe_i)begin
            if(!(cpol_i ^ cpha_i))begin
                //$display("TIME=%t | tb_data_mosi=%b | PCLK=%b | ss_o=%b | snd_data_i=%b | lsb/cp/h=%b%b%b | miso_rcv=%b | mosi_snd=%b | data_mosi_i=%h | miso_i=%b | rcv_data=%b | mosi_o=%b | data_miso_o=%h | temp_reg=%b | perefData=%b",$time, tb_data_mosi,PCLK,ss_o,send_data_i,lsbfe_i,cpol_i,cpha_i,miso_receive_sclk_o,mosi_send_sclk_o,data_mosi_i,miso_i,receive_data_o,mosi_o,data_miso_o,DUT_shifter.temp_reg,perefData);
                for(countmosi=0;countmosi<8;countmosi=countmosi+1)begin
                    wait(mosi_send_sclk_o);
                    repeat(2)@(negedge PCLK);
                    if(tb_data_mosi[countmosi] !== mosi_o)begin
                        $display("TIME=%t | FAIL DATA MISMATCH %b != %b (mosi_o)",$time,tb_data_mosi[countmosi],mosi_o);
                        Errtime[error_count] <= $time;
                        error_count <= error_count + 1;
                    end else begin
                        $display("TIME=%t | PASS DATA MATCH %b = %b (mosi_o)",$time,tb_data_mosi[countmosi],mosi_o);
                    end
                end
                wait(ss_o);
            end else if(cpol_i ^ cpha_i)begin
              // $display("TIME=%t | tb_data_mosi=%b | PCLK=%b | ss_o=%b | snd_data_i=%b | lsb/cp/h=%b%b%b | miso_rcv=%b | mosi_snd=%b | data_mosi_i=%h | miso_i=%b | rcv_data=%b | mosi_o=%b | data_miso_o=%h | temp_reg=%b | perefData=%b",$time, tb_data_mosi,PCLK,ss_o,send_data_i,lsbfe_i,cpol_i,cpha_i,miso_receive_sclk_o,mosi_send_sclk_o,data_mosi_i,miso_i,receive_data_o,mosi_o,data_miso_o,DUT_shifter.temp_reg,perefData);
                for(countmosi=0;countmosi<8;countmosi=countmosi+1)begin
                    wait(mosi_send_sclk0_o);
                    repeat(2)@(negedge PCLK);
                    if(tb_data_mosi[countmosi] !== mosi_o)begin
                        $display("TIME=%t | FAIL DATA MISMATCH %b != %b (mosi_o)",$time,tb_data_mosi[countmosi],mosi_o);
                        Errtime[error_count] <= $time;
                        error_count <= error_count + 1;
                    end else begin
                        $display("TIME=%t | PASS DATA MATCH %b = %b (mosi_o)",$time,tb_data_mosi[countmosi],mosi_o);
                    end
                end
                wait(ss_o);
            end
        end else if(~lsbfe_i)begin
             if(!(cpol_i ^ cpha_i))begin
                //$display("TIME=%t | tb_data_mosi=%b | PCLK=%b | ss_o=%b | snd_data_i=%b | lsb/cp/h=%b%b%b | miso_rcv=%b | mosi_snd=%b | data_mosi_i=%h | miso_i=%b | rcv_data=%b | mosi_o=%b | data_miso_o=%h | temp_reg=%b | perefData=%b",$time, tb_data_mosi,PCLK,ss_o,send_data_i,lsbfe_i,cpol_i,cpha_i,miso_receive_sclk_o,mosi_send_sclk_o,data_mosi_i,miso_i,receive_data_o,mosi_o,data_miso_o,DUT_shifter.temp_reg,perefData);
                for(countmosi=7;countmosi>=0;countmosi=countmosi-1)begin
                    wait(mosi_send_sclk_o);
                    repeat(2)@(negedge PCLK);
                    if(tb_data_mosi[countmosi] !== mosi_o)begin
                        $display("TIME=%t | FAIL DATA MISMATCH %b != %b (mosi_o)",$time,tb_data_mosi[countmosi],mosi_o);
                        Errtime[error_count] <= $time;
                        error_count <= error_count + 1;
                    end else begin
                        $display("TIME=%t | PASS DATA MATCH %b = %b (mosi_o)",$time,tb_data_mosi[countmosi],mosi_o);
                    end
                end
                wait(ss_o);
            end else if(cpol_i ^ cpha_i)begin
                //$display("TIME=%t | tb_data_mosi=%b | PCLK=%b | ss_o=%b | snd_data_i=%b | lsb/cp/h=%b%b%b | miso_rcv=%b | mosi_snd=%b | data_mosi_i=%h | miso_i=%b | rcv_data=%b | mosi_o=%b | data_miso_o=%h | temp_reg=%b | perefData=%b",$time, tb_data_mosi,PCLK,ss_o,send_data_i,lsbfe_i,cpol_i,cpha_i,miso_receive_sclk_o,mosi_send_sclk_o,data_mosi_i,miso_i,receive_data_o,mosi_o,data_miso_o,DUT_shifter.temp_reg,perefData);
                for(countmosi=7;countmosi>=0;countmosi=countmosi-1)begin
                    wait(mosi_send_sclk0_o);
                    repeat(2)@(negedge PCLK);
                    if(tb_data_mosi[countmosi] !== mosi_o)begin
                        $display("TIME=%t | FAIL DATA MISMATCH %b != %b (mosi_o)",$time,tb_data_mosi[countmosi],mosi_o);
                        Errtime[error_count] <= $time;
                        error_count <= error_count + 1;
                    end else begin
                        $display("TIME=%t | PASS DATA MATCH %b = %b (mosi_o)",$time,tb_data_mosi[countmosi],mosi_o);
                    end
                end
                wait(ss_o);
            end
        end

    end

initial begin
#10;
reset_dut();
end

initial begin
    $timeformat(-9,1,"ns",8);
tb_data_mosi = 8'hA9;
@(posedge PCLK);
$display("TIME %t | NOW PASSING DATA 1 cpol/cpha=11,lsbfe=1,spidwai=0,data_mosi=%b,mode=00,sppr=0,spr=0",$time,tb_data_mosi);
fork
setcpolCpha(1'b1,1'b1);
runDUT(1'b1,1'b0,tb_data_mosi,2'b00,3'b000,3'b000);    //sendData//, Lsbfe, Spiswai, Data_MOSI, SPI_Mode, Sppr, Spr
join

wait(receive_data_o);
repeat(2)@(posedge PCLK);
if(data_miso_o !== perefData)begin
$display("TIME=%t | FAIL DATA MISMATCH %h != %h (data_miso_o)",$time,perefData,data_miso_o);
Errtime[error_count] <= $time;
error_count <= error_count + 1;
end else 
$display("data_miso | PASS MATCHED | DATA SENT = %h | DATA RECEIVED = %h",perefData,data_miso_o);
#100;
perefData = 8'b1010_1001;
#400; 
////////////////////////////////////////////////////////////

tb_data_mosi = 8'h4c;
@(posedge PCLK);
$display("TIME %t | NOW PASSING DATA 2 cpol/cpha=00,lsbfe=0,spidwai=0,data_mosi=%b,mode=00,sppr=0,spr=0",$time,tb_data_mosi);

fork
setcpolCpha(1'b0,1'b0);
runDUT(1'b0,1'b0,tb_data_mosi,2'b00,3'b000,3'b000);    //sendData//, Lsbfe, Spiswai, Data_MOSI, SPI_Mode, Sppr, Spr
join

wait(receive_data_o);
repeat(2)@(posedge PCLK);
if(data_miso_o !== perefData)begin     // accumulated sata received from pereferal  1001_1010   0101_1001
$display("FAIL DATA MISMATCH %h != %h",perefData,data_miso_o);       
Errtime[error_count] <= $time;
error_count <= error_count + 1;
//$finish;  // for lsbfe=0 output will reverse as out tb pereferal will send same data but dut will reverse it 
end else 
$display("data_miso | PASS MATCHED | DATA SENT %h | DATA RECEIVED = %h",perefData,data_miso_o);

#100;
perefData = 8'b1010_1011;
#400;
///////////////////////////////////////////////////////////////

tb_data_mosi = 8'h7b ;
@(posedge PCLK);
$display("TIME %t | NOW PASSING DATA 3 cpol/cpha=00,lsbfe=1,spidwai=0,data_mosi=%b,mode=00,sppr=0,spr=1",$time,tb_data_mosi);

fork
setcpolCpha(1'b0,1'b0);
runDUT(1'b1,1'b0,tb_data_mosi,2'b00,3'b000,3'b001);    //sendData//, Lsbfe, Spiswai, Data_MOSI, SPI_Mode, Sppr, Spr
join

wait(receive_data_o);
repeat(2)@(posedge PCLK);
if(data_miso_o !== perefData)begin     // accumulated sata received from pereferal  
$display("FAIL DATA MISMATCH not 9a =%h",data_miso_o);  
Errtime[error_count] <= $time;
error_count <= error_count + 1;     
//$finish;  // for lsbfe=0 output will reverse as out tb pereferal will send same data but dut will reverse it 
end else 
$display("data_miso | PASS MATCHED | DATA SENT = %h | DATA RECEIVED = %h",perefData,data_miso_o);

#100;
perefData = 8'b1010_1111;
#400;
//////////////////////////////////////////////////////////////////

tb_data_mosi = 8'h6d ;
@(posedge PCLK);
$display("TIME %t | NOW PASSING DATA 4 cpol/cpha=10,lsbfe=1,spidwai=0,data_mosi=%b,mode=00,sppr=0,spr=1",$time,tb_data_mosi);

fork
setcpolCpha(1'b1,1'b0);
runDUT(1'b1,1'b0,tb_data_mosi,2'b00,3'b000,3'b001);    //sendData//, Lsbfe, Spiswai, Data_MOSI, SPI_Mode, Sppr, Spr
join

wait(receive_data_o);
repeat(2)@(posedge PCLK);
if(data_miso_o !== perefData)begin     // accumulated sata received from pereferal  
$display("FAIL DATA MISMATCH not 9a =%h",data_miso_o);  
Errtime[error_count] <= $time;
error_count <= error_count + 1;     
//$finish;  // for lsbfe=0 output will reverse as out tb pereferal will send same data but dut will reverse it 
end else 
$display("data_miso | PASS MATCHED | DATA SENT = %h | DATA RECEIVED = %h",perefData,data_miso_o);

#500;

///////////////////////////////////////////////////////////////////

tb_data_mosi = 8'h54 ;
@(posedge PCLK);
$display("TIME %t | NOW PASSING DATA 5 cpol/cpha=01,lsbfe=1,spidwai=0,data_mosi=%b,mode=00,sppr=0,spr=1",$time,tb_data_mosi);

fork
setcpolCpha(1'b0,1'b1);
runDUT(1'b1,1'b0,tb_data_mosi,2'b00,3'b000,3'b001);    //sendData//, Lsbfe, Spiswai, Data_MOSI, SPI_Mode, Sppr, Spr
join

wait(receive_data_o);
repeat(2)@(posedge PCLK);
if(data_miso_o !== perefData)begin     // accumulated sata received from pereferal  
$display("FAIL DATA MISMATCH not 9a =%h",data_miso_o);  
Errtime[error_count] <= $time;
error_count <= error_count + 1;     
//$finish;  // for lsbfe=0 output will reverse as out tb pereferal will send same data but dut will reverse it 
end else 
$display("data_miso | PASS MATCHED | DATA SENT = %h | DATA RECEIVED = %h",perefData,data_miso_o);

#500;

///////////////////////////////////////////////////////////////////

#5000;


if (error_count == 0)
        $display(" ///////////// ALL TEST PASSED ////////////");
    else
        $display("/////////////// TEST FAILED with %0d errors //////////////", error_count);

    for(j=0;j<error_count;j=j+1)begin
     $display("ERRTIME=[%t]",Errtime[j]);
     #1;
     end
     #50;
$finish;
end

//initial $monitor("real val =%b",receive_data_o);
//initial $monitor("TIME=%t, MOSI=%b SCLK=%b count=%d mosi_send=%b data=%b",$time,mosi_o,sclk_o,count00,mosi_send_sclk_o,DUT_shifter.shift_register);
//initial $monitor("TIME=%t,  count=%d, receive=%b senddata=%b",$time,count00,DUT_shifter.receive_data_i,send_data_i);
//* initial $monitor("TIME=%t | PCLK=%b | ss_o=%b | snd_data_i=%b | lsb/cp/h=%b%b%b | miso_rcv=%b | mosi_snd=%b | data_mosi_i=%h | miso_i=%b | rcv_data=%b | mosi_o=%b | data_miso_o=%h | temp_reg=%b | perefData=%b",$time,PCLK,ss_o,send_data_i,lsbfe_i,cpol_i,cpha_i,miso_receive_sclk_o,mosi_send_sclk_o,data_mosi_i,miso_i,receive_data_o,mosi_o,data_miso_o,DUT_shifter.temp_reg,perefData);
//initial $monitor("TIME=%t, PCLK=%b, ss_i=%b, send_data_i=%b, lsbfe=%b, cpha=%b, cpol=%b | miso_receive=%b | miso_receive0=%b,mosi_send=%b, miso_send0=%b,data_mosi=%h,mosi_i=%b,receive_data=%b, mosi_o=%b, data_miso_o=%h",$time,PCLK,ss_o,send_data_i,lsbfe_i,cpha_i,cpol_i,miso_receive_sclk_o,miso_receive_sclk0_o,mosi_send_sclk_o,mosi_send_sclk0_o,data_mosi_i,miso_i,receive_data_o,mosi_o,data_miso_o);
//initial $monitor("data_miso_o=%b",data_miso_o);
endmodule


//////////////////////////////////////////////////////////////////////
