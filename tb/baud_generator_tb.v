`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.03.2026 22:04:40
// Design Name: 
// Module Name: baud_generator_tb
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


`timescale 1ns/1ps

module baud_generator_tb;

reg PCLK;
reg PRESET_n;
reg [1:0] spi_mode_i;
reg spiswai_i;
reg [2:0] sppr_i;
reg [2:0] spr_i;
reg cpol_i;
reg cpha_i;
reg ss_i;

wire sclk_o;
wire miso_receive_sclk_o;
wire miso_receive_sclk0_o;
wire mosi_send_sclk_o;
wire mosi_send_sclk0_o;
wire [11:0] BaudRateDivisor_o;

baud_generator DUT(
    .PCLK(PCLK),
    .PRESET_n(PRESET_n),
    .spi_mode_i(spi_mode_i),
    .spiswai_i(spiswai_i),
    .sppr_i(sppr_i),
    .spr_i(spr_i),
    .cpol_i(cpol_i),
    .cpha_i(cpha_i),
    .ss_i(ss_i),
    .sclk_o(sclk_o),
    .miso_receive_sclk_o(miso_receive_sclk_o),
    .miso_receive_sclk0_o(miso_receive_sclk0_o),
    .mosi_send_sclk_o(mosi_send_sclk_o),
    .mosi_send_sclk0_o(mosi_send_sclk0_o),
    .BaudRateDivisor_o(BaudRateDivisor_o)
);

reg [11:0] localBaud;
reg prev_sclk=0, prev_ss_i=1;
integer i,j;
integer error_count = 0;
reg [32:0]Errtime [7:0];
reg cycleDelay1=0, cycleDelay2=0,cycleDelay3=0, start_check=0;

initial
    PCLK = 0;

always #20 PCLK = ~PCLK;



initial begin
/* PRESET_n   = 1;
spi_mode_i = 2'b00;
spiswai_i  = 1;
sppr_i     = 3'b000;
spr_i      = 3'b001;
cpol_i     = 0;
cpha_i     = 0; */
//ss_i       = 1;
end  

task resetDUT();
begin
PRESET_n = 0;
repeat(3) @(posedge PCLK);
PRESET_n = 1;
end
endtask

task mode00(input [2:0] presel_bit, input [2:0]sel_bit, input [1:0]spimod, input spiswai);
begin
@(negedge PCLK);
sppr_i     = presel_bit;
spr_i      = sel_bit;
spi_mode_i = spimod;
spiswai_i  = spiswai;
cpol_i     = 0;
cpha_i     = 0;
localBaud= (presel_bit+1)*(2**(sel_bit+1));
repeat(10) @(negedge PCLK);

    ss_i = 0; // start transaction

    if (spimod == 2'd1 && spiswai == 1) begin
        // WAIT mode → clock should stop
        repeat(50) @(posedge PCLK);
    end else begin
        for (i = 0; i < 8; i = i + 1) begin
            wait (sclk_o == 1);
            wait (sclk_o == 0);
        end
    end

    ss_i = 1; // end transaction

    repeat(10) @(negedge PCLK);
end
endtask

task mode01(input [2:0] presel_bit, input [2:0]sel_bit, input [1:0]spimod, input spiswai);
begin
@(negedge PCLK);
sppr_i     = presel_bit;
spr_i      = sel_bit;
spi_mode_i = spimod;
spiswai_i  = spiswai;
cpol_i     = 0;
cpha_i     = 1;
localBaud= (presel_bit+1)*(2**(sel_bit+1));
repeat(10) @(negedge PCLK);

    ss_i = 0; // start transaction

    if (spimod == 2'd1 && spiswai == 1) begin
        // WAIT mode ? clock should stop
        repeat(50) @(posedge PCLK);
    end else begin
        for (i = 0; i < 8; i = i + 1) begin
            wait (sclk_o == 1);
            wait (sclk_o == 0);
        end
    end

    ss_i = 1; // end transaction

    repeat(10) @(negedge PCLK);
end
endtask

task mode10(input [2:0] presel_bit, input [2:0]sel_bit, input [1:0]spimod, input spiswai);
begin
@(negedge PCLK);
sppr_i     = presel_bit;
spr_i      = sel_bit;
spi_mode_i = spimod;
spiswai_i  = spiswai;
cpol_i     = 1;
cpha_i     = 0;
localBaud= (presel_bit+1)*(2**(sel_bit+1));
repeat(10) @(negedge PCLK);

    ss_i = 0; // start transaction

    if (spimod == 2'd1 && spiswai == 1) begin
        // WAIT mode ? clock should stop
        repeat(50) @(posedge PCLK);
    end else begin
        for (i = 0; i < 8; i = i + 1) begin
            wait (sclk_o == 1);
            wait (sclk_o == 0);
        end
    end
    //#1;
    ss_i = 1; // end transaction

    repeat(10) @(negedge PCLK);
end
endtask

task mode11(input [2:0] presel_bit, input [2:0]sel_bit, input [1:0]spimod, input spiswai);
begin
@(negedge PCLK);
sppr_i     = presel_bit;
spr_i      = sel_bit;
spi_mode_i = spimod;
spiswai_i  = spiswai;
cpol_i     = 1;
cpha_i     = 1;
localBaud= (presel_bit+1)*(2**(sel_bit+1));
repeat(10) @(negedge PCLK);

    ss_i = 0; // start transaction

    if (spimod == 2'd1 && spiswai == 1) begin
        // WAIT mode ? clock should stop
        repeat(50) @(posedge PCLK);
    end else begin
        for (i = 0; i < 8; i = i + 1) begin
            wait (sclk_o == 1);
            wait (sclk_o == 0);
        end
    end

    ss_i = 1; // end transaction

    repeat(10) @(negedge PCLK);
end
endtask

always @(posedge PCLK) begin
    if (ss_i == 0) begin
        if (BaudRateDivisor_o !== localBaud) begin
            $display("ERROR @%t: Div mismatch exp=%0d got=%0d",
                     $time, localBaud, BaudRateDivisor_o);
                     Errtime[error_count] = $time;
                     error_count = error_count + 1;
        end
    end
end

always @(posedge PCLK) begin
    if(start_check) begin
    cycleDelay1 <= (ss_i == 1 && prev_ss_i == 0);
    cycleDelay2 <= (ss_i == 1 && prev_ss_i == 1 && sclk_o !== prev_sclk);
   // cycleDelay3 <= (spi_mode_i == 2'd1 && spiswai_i == 1);
    //if(cycleDelay1)begin
      //  cycleDelay3 = 1;
    //end
    if (cycleDelay1) begin 
        @(posedge PCLK);
        if(sclk_o !== cpol_i) begin
        $display("ERROR @%t: CPOL violation (idle level wrong) sclk_o=%b, cpol_i=%b", $time, sclk_o,cpol_i);
        Errtime[error_count] <= $time;
        error_count <= error_count + 1;
        end
        //cycleDelay3 <= 0;
    end

    if (cycleDelay2 && (sclk_o !== cpol_i)) begin
        $display("ERROR @%t: SCLK toggling when SS inactive", $time);
        Errtime[error_count] = $time;
        error_count = error_count + 1;
    end
    prev_sclk <= sclk_o;
    prev_ss_i <= ss_i;
    
   /* if(cycleDelay3)begin
    if (sclk_o !== prev_sclk)
    $display("ERROR @%t: SCLK toggling in WAIT mode", $time);
    Errtime[error_count] = $time;
    error_count = error_count + 1;
    end  */

    end
end

initial begin
#100;
    start_check = 1;
end

initial begin
#10;
resetDUT();
end

initial begin
    $timeformat(-9,0,"ns",7);

    #10;
    //resetDUT();

//------------------------------------------------------------------
    ss_i = 1;
   // repeat(5) @(posedge PCLK);
   @(posedge PCLK);
   $display("Time=%t | Passing mode00(sppr_i=3'd0,spr_i=3'd1,spi_mode_i=2'd0,spiswai=0)",$time);
    mode00(3'd0,3'd1,2'd0,0);
    #500;
//-----------------------------------------------------------------
    ss_i = 1;
    @(posedge PCLK);
    $display("Time=%t | Passing mode00(sppr_i=3'd0,spr_i=3'd0,spi_mode_i=2'd0,spiswai=0)",$time);
    mode00(3'd0,3'd0,2'd0,0); 
    #500;
//-------------------------------------------------------------------
    ss_i = 1;
    @(posedge PCLK);
    $display("Time=%t | Passing mode00(sppr_i=3'd1,spr_i=3'd1,spi_mode_i=2'd1,spiswai=1)",$time);
    mode00(3'd1,3'd1,2'd1,1);
    #500;
//--------------------------------------------------------------------
    
    ss_i = 1;
    repeat(1) @(posedge PCLK);   //(5)
    $display("Time=%t | Passing mode01(sppr_i=3'd0,spr_i=3'd0,spi_mode_i=2'd0,spiswai=0)",$time);
    mode01(3'd0,3'd1,2'd0,0);
    #500;
//---------------------------------------------------------------
   
    ss_i = 1;
    //repeat(5) @(posedge PCLK);
      @(posedge PCLK);
    $display("Time=%t | Passing mode10(sppr_i=3'd0,spr_i=3'd0,spi_mode_i=2'd0,spiswai=0)",$time);
    mode10(3'd0,3'd0,2'd0,0);
    #500;
//----------------------------------------------------------------
    //$display("changing ss_i");
    ss_i = 1;
    repeat(1) @(posedge PCLK);
    $display("Time=%t | Passing mode11(sppr_i=3'd1,spr_i=3'd1,spi_mode_i=2'd0,spiswai=0)",$time);
    mode11(3'd1,3'd1,2'd0,0);
//------------------------------------------------------------------
    
    $display("Time=%t | changing ss_i",$time);
    ss_i = 1;
    repeat(1) @(posedge PCLK);
    $display("Time=%t | Passing mode11(sppr_i=3'd1,spr_i=3'd1,spi_mode_i=2'd1,spiswai=1)",$time);
    mode11(3'd1,3'd1,2'd1,1);
//-----------------------------------------------------------------    
    #5000;
    if (error_count == 0)
        $display("? TEST PASSED");
    else
        $display("? TEST FAILED with %0d errors", error_count);

    for(j=0;j<error_count;j=j+1)begin
     $display("ERRTIME=[%t]",Errtime[j]);
     #1;
     end
#50;
$finish;
end


initial begin
/*$monitor("Time=%t PC=%b ss_i=%b count_s=%0d sclk_o=%b Bdivisor=%0d miso_r=%b miso_r0=%b mosi_s=%b mosi_s0=%b, cpol_i=%b, cpha_i=%b",
          $time, PCLK, ss_i, DUT.count_s, sclk_o, BaudRateDivisor_o,
          miso_receive_sclk_o, miso_receive_sclk0_o, mosi_send_sclk_o,mosi_send_sclk0_o,cpol_i, cpha_i);
*/
$monitor("TIME=%t | PCLK=%b| ss_i=%b | pre_sclk_s=%b | sclk_o=%b | cpol_i=%b | cpha_i=%b | miso_rcv_sclk_o = %b |  mosi_snd_sclk_o = %b | miso_rcv_sclk0_o = %b | mosi_snd_sclk0_o = %b",$time,PCLK,ss_i,DUT.pre_sclk_s,sclk_o,cpol_i,cpha_i,miso_receive_sclk_o,mosi_send_sclk_o,miso_receive_sclk0_o,mosi_send_sclk0_o);
//$monitor("ss_rising=%b",DUT.ss_rising);
end

endmodule
