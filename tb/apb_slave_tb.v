`timescale 1ns/1ps

module apb_slave_tb();

reg PCLK;
reg PRESET_n;

reg [2:0] PADDR_i;
reg PWRITE_i;
reg PSEL_i;
reg PENABLE_i;
reg [7:0] PWDATA_i;

reg ss_i;
reg [7:0] miso_data_i;
reg receive_data_i;
reg tip_i;

wire [7:0] PRDATA_o;
wire mstr_o;
wire cpol_o;
wire cpha_o;
wire lsbfe_o;
wire spiswai_o;
wire [2:0] sppr_o;
wire [2:0] spr_o;
wire spi_interrupt_request_o;
wire PREADY_o;
wire PSLVERR_o;
wire send_data_o;
wire [7:0] mosi_data_o;
wire [1:0] spi_mode_o;


apb_slave DUT(
PCLK, PRESET_n,
PADDR_i, PWRITE_i, PSEL_i, PENABLE_i,
PWDATA_i,
ss_i,
miso_data_i,
receive_data_i,
tip_i,
PRDATA_o,
mstr_o,
cpol_o,
cpha_o,
lsbfe_o,
spiswai_o,
sppr_o,
spr_o,
spi_interrupt_request_o,
PREADY_o,
PSLVERR_o,
send_data_o,
mosi_data_o,
spi_mode_o
);

parameter Add_SPI_CR1 = 3'b000, Add_SPI_CR2 = 3'b001, Add_SPI_BR  = 3'b010, Add_SPI_SR  = 3'b011, Add_SPI_DR  = 3'b101;
parameter SPI_CR1 = 8'b11110110, SPI_CR2 = 8'b00010000, SPI_BR  = 8'b00010001 ; // Add_SPI_SR  = 3'b011, Add_SPI_DR  = 3'b101;

wire [12:0] BaudRateDivisor_local ;

assign BaudRateDivisor_local = ((SPI_BR[6:4]+1)<<(SPI_BR[2:0]+1));

reg err=0,dummy;
event runSPI;

always #20 PCLK = ~PCLK;
initial PCLK = 0;

initial begin
PADDR_i  = 3'b000;
PWRITE_i = 0;
PSEL_i   = 0;
PENABLE_i = 0;
PWDATA_i  = 8'h00;
PRESET_n = 1;
ss_i     = 1;
miso_data_i  = 8'h4B; 
receive_data_i = 0;
tip_i    = 0;

end

task phseidle();
begin
@(posedge PCLK);
PWRITE_i = 0;
PSEL_i   = 0;
PENABLE_i = 0;
PWDATA_i  = 8'h00;
end
endtask

task apb_SetupWrite(input [2:0]address, input [7:0]wdata);
begin
@(posedge PCLK);
    PADDR_i  = address;
    PWRITE_i = 1;
    PSEL_i   = 1;
    PENABLE_i = 0;
    PWDATA_i  = wdata;
end
endtask

task apb_Access(output reg pslverr_sample);
begin
@(posedge PCLK);
    PENABLE_i = 1;
@(posedge PCLK);
    pslverr_sample = PSLVERR_o;

    if(PREADY_o !== 1)
        $display("ERROR= %0t : PREADY not asserted in ENABLE",$time);
        else
        $display("PASS= %0t : PREADY asserted in ENABLE",$time);

    PENABLE_i = 0;
end
endtask

task apb_SetupRead(input [2:0]address);
begin
@(posedge PCLK);
    PADDR_i  = address;
    PWRITE_i = 0;
    PSEL_i   = 1;
    PENABLE_i = 0;
end
endtask

/* task apb_AccessRead();
begin
@(posedge PCLK);
    PENABLE_i = 1;
@(posedge PCLK);
    PENABLE_i = 0;
end
endtask  */

task writeSingle(input [2:0]address, input [7:0]wdata);
begin
apb_SetupWrite(address , wdata);
apb_Access(dummy);
//@(posedge PCLK);
phseidle();
end
endtask

task writeMulti(input [2:0]address, input [7:0]wdata);
begin
apb_SetupWrite(address , wdata);
apb_Access(err);
end
endtask

task readSingle(input [2:0]address);
begin
apb_SetupRead(address);
apb_Access(dummy);
//phseidle();
end
endtask


task resetdut;
begin
PRESET_n = 0;
repeat(3) @(posedge PCLK);
PRESET_n = 1;
end
endtask

initial begin
phseidle();
#10;
resetdut();
@(posedge PCLK);
readSingle(Add_SPI_CR1);
if (PRDATA_o !== 8'h04)
    $display("ERROR: Reset CR1 wrong");
    else
    $display("PASS: Reset CR1 correct");
phseidle();

repeat(5) @(posedge PCLK);
writeSingle(Add_SPI_CR1 , SPI_CR1);             
repeat(5) @(posedge PCLK);
writeMulti(Add_SPI_CR2 , SPI_CR2);
writeMulti(Add_SPI_BR  , SPI_BR);
writeMulti(Add_SPI_DR  , 8'b10110101);               // D Reg
repeat(5) @(posedge PCLK);
phseidle();

writeMulti(3'b110, 8'hAA);            //to test for wrong address error
if (err !== 1)
    $display("ERROR: PSLVERR not asserted for invalid addr");
    else
    $display("PASS: PSLVERR asserted for invalid addr");
phseidle();

#200;
@(posedge PCLK);

readSingle(Add_SPI_CR1);
if (PRDATA_o !== 8'b11110110)
    $display("ERROR: CR1 write failed");
    else
    $display("PASS: CR1 OK");
phseidle();

readSingle(Add_SPI_CR2);
if (PRDATA_o !== (8'h1B & 8'h10))
    $display("ERROR: CR2 write failed");
    else
    $display("PASS: CR2 OK");
phseidle();

readSingle(Add_SPI_BR);
if (PRDATA_o !== (8'h77 & 8'h11))
    $display("ERROR: BR write failed");
    else
    $display("PASS: BR OK");
phseidle();

readSingle(Add_SPI_DR);
if (PRDATA_o !== 8'b10110101)
    $display("ERROR: DR write failed");
    else
    $display("PASS: DR OK");
phseidle();

->runSPI;

repeat(BaudRateDivisor_local << 4) @(posedge PCLK);
//wait(receive_data_i == 1);
@(posedge PCLK);  //extra wait cycle to stablise
readSingle(Add_SPI_DR);              // check miso_data_i data from pereferal
if (PRDATA_o !== 8'b11001100)
    $display("ERROR: DR write failed");
    else
    $display("PASS: DR OK");
phseidle();


#5000;
$finish;

end


always begin
@(runSPI); // wait until transmission starts
//@(posedge send_data_o);   
ss_i  = 0; 
tip_i = ~ss_i;

repeat(BaudRateDivisor_local << 4) @(posedge PCLK);

miso_data_i = 8'b11001100;

receive_data_i = 1;
@(posedge PCLK);
receive_data_i = 0;

ss_i  = 1; 
tip_i = ~ss_i;

receive_data_i = 0;

end

 initial $monitor("TIME=%0t | APB_STATE=%0d | PSEL=%b PENABLE=%b PWRITE=%b ADDR=%h WDATA=%h | PRDATA=%h | PREADY=%b | SEND=%b | MOSI_DATA=%h | SPI_MODE=%b",
            $time, DUT.apb_present_state, PSEL_i, PENABLE_i, PWRITE_i, PADDR_i,PWDATA_i,PRDATA_o,PREADY_o,send_data_o,mosi_data_o,spi_mode_o
            ); 



endmodule
