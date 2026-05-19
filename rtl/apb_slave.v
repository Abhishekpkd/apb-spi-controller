`define SPI_APB_DATA_WIDTH 8
`define SPI_REG_WIDTH 8
`define SPI_APB_ADDR_WIDTH 3

module apb_slave(
    input PCLK,
    input PRESET_n,
    input [2:0]PADDR_i,
    input PWRITE_i,
    input PSEL_i,
    input PENABLE_i,
    input [7:0] PWDATA_i,
    input ss_i,
    input [7:0]miso_data_i,
    input receive_data_i,
    input tip_i,
    output reg [7:0] PRDATA_o,
    output mstr_o,
    output cpol_o,
    output cpha_o,
    output lsbfe_o,
    output spiswai_o,
    output [2:0] sppr_o,
    output [2:0] spr_o,
    output spi_interrupt_request_o,
    output reg PREADY_o,
    output reg PSLVERR_o,
    output reg send_data_o,       //to initiate serial communication between spi and pherepheral
    output reg [7:0]mosi_data_o,
    output [1:0]spi_mode_o
);

reg [1:0] apb_present_state,apb_next_state;
reg [1:0]spi_mode_present, spi_mode_next;
reg [7:0]SPI_CR1, SPI_CR2, SPI_BR, SPI_SR, SPI_DR;
reg [7:0] latched_receive_data;

wire sptef;
reg spif;
wire modf,modfen;
wire spie,spe,sptie;
wire wr_enb,rd_enb,apb_access;
wire SSOE;

localparam IDLE = 2'b00, SETUP = 2'b01, ENABLE = 2'b10 ;    //APB STATES FSM
localparam SPI_RUN = 2'b00, SPI_WAIT = 2'b01, SPI_STOP = 2'b10;   //SPI MODES FSM


//SPI_CR1
assign lsbfe_o = SPI_CR1[0];
assign SSOE    = SPI_CR1[1];
assign cpha_o  = SPI_CR1[2];
assign cpol_o  = SPI_CR1[3];
assign mstr_o  = SPI_CR1[4];
assign sptie   = SPI_CR1[5];
assign spe     = SPI_CR1[6];
assign spie    = SPI_CR1[7];

//SPI_CR2
assign spiswai_o = SPI_CR2[1];
assign modfen    = SPI_CR2[4];

//SPI_BR
assign sppr_o    = SPI_BR[6:4];
assign spr_o     = SPI_BR[2:0];

//SPI_SR
assign modf = (~ss_i && mstr_o && modfen && ~SSOE);
assign sptef = ~tip_i;        // transmit buffer empty when no transfer running
//assign spif = receive_data_i;  //data received cpu can read now

//SPI_SR
always @(posedge PCLK or negedge PRESET_n)begin
 if(~PRESET_n) begin
    SPI_SR <= 8'h20;
    spif <= 0;
 end else begin
        if(receive_data_i)begin
            spif <= 1;
        end else if(rd_enb && PADDR_i == 3'b101) begin
            spif <= 0;
        end

        SPI_SR <= {spif,1'b0,sptef,modf,4'b0};
    end
end


assign apb_access = PSEL_i && PENABLE_i;

assign wr_enb = apb_access && PWRITE_i;
assign rd_enb = apb_access && ~PWRITE_i;

assign spi_interrupt_request_o = (~spie&&!sptie) ? 0 :
((spie&&~sptie)&&(spif || modf)) ? 1 :
((~spie && sptie) && sptef) ? 1 :
(sptef||modf||spif);

assign spi_mode_o = spi_mode_present;

//wire check_miso_or_cpuwrite = ((SPI_RUN || SPI_WAIT) && receive_data_i);


//reg flag_setup_count=0;
 
/* always @(posedge PCLK or negedge PRESET_n)begin: APB_FSM_PRESENT
    if(~PRESET_n)begin
        apb_present_state <= IDLE ;
    end else
        apb_present_state <= apb_next_state;
end

always @(*)begin: APB_FSM_NEXT_COMBINATIONAL
    apb_next_state = apb_present_state;
    case (apb_present_state)
        IDLE: begin
            if(PSEL_i && ~PENABLE_i)
                apb_next_state = SETUP;
            else
                apb_next_state = IDLE;        //IDLE
        end
        SETUP: begin
            if(PSEL_i && PENABLE_i)begin
                apb_next_state = ENABLE;
            end else if(PSEL_i && ~PENABLE_i) begin
                apb_next_state = apb_present_state;
            end else if(~PSEL_i)begin
                apb_next_state = IDLE;
            end
        end 
        ENABLE: begin
            if(PSEL_i )begin
                apb_next_state = SETUP;
            end else begin
            apb_next_state = IDLE;
            end
        end
        default: apb_next_state = IDLE;
    endcase
end  */


    always @(*) begin: SAME_CYCLE_ZERO_WAIT
        PREADY_o = 0;
        PSLVERR_o = 0;
        if(PSEL_i && PENABLE_i)begin
            PREADY_o = 1;
            PSLVERR_o = (PADDR_i > 3'b101);     // error if invalid address
        end
    end


always @(posedge PCLK or negedge PRESET_n)begin: WRITE_DATA_TO_CR_AND_BR_REG
    if(~PRESET_n)begin
        SPI_CR1 <= 8'h04;
        SPI_CR2 <= 8'h00;
        SPI_BR  <= 8'h00;
    end else if(wr_enb)begin
        case (PADDR_i)
            3'b000: SPI_CR1 <= PWDATA_i;
            3'b001: SPI_CR2 <= (8'h1B & PWDATA_i);   //mask 0001_1011
            3'b010: SPI_BR  <= (8'h77 & PWDATA_i);     //mask 0111_0111  
            default: ;  
        endcase
    end
end


always @(posedge PCLK or negedge PRESET_n)begin: WRITE_DATA_TO_DR
    if(~PRESET_n)begin
        SPI_DR <= 8'h00;
        latched_receive_data <= 0;
    //end else if(((spi_mode_present == SPI_RUN)||(spi_mode_present==SPI_WAIT)) && receive_data_i)begin
    end else if(receive_data_i)begin     // if wr_enb and receive both high receive first from pereferal miso
        latched_receive_data <= 1;
    end else if(latched_receive_data) begin
        SPI_DR <= miso_data_i;
        latched_receive_data <= 0;
    end else if(wr_enb && (PADDR_i == 3'b101))begin
        SPI_DR <= PWDATA_i;
    end
end


/*always @(posedge PCLK or negedge PRESET_n)begin
    if(~PRESET_n)begin
        SPI_DR <= 8'h00;
    end else if(wr_enb && (PADDR_i == 3'b101))begin
        SPI_DR <= PWDATA_i;
    //end else if(((spi_mode_present == SPI_RUN)||(spi_mode_present==SPI_WAIT)) && receive_data_i)begin
    end else if(!tip_i && receive_data_i)begin
        SPI_DR <= miso_data_i;
    end
end  */

always @(*) begin : READ_DATA_FROM_REG
    if(rd_enb) begin
        case (PADDR_i)
            3'b000: PRDATA_o = SPI_CR1;
            3'b001: PRDATA_o = SPI_CR2;
            3'b010: PRDATA_o = SPI_BR;
            3'b011: PRDATA_o = SPI_SR;
            3'b101: PRDATA_o = SPI_DR; 
           default: PRDATA_o = 8'h00;
        endcase
    end else begin
            PRDATA_o = 8'h00;
    end
end


//SPI MODE ---------------------------------------------------------------

always @(posedge PCLK or negedge PRESET_n)begin
    if(~PRESET_n)
        spi_mode_present <= SPI_RUN;
        else
        spi_mode_present <= spi_mode_next;
end

always @(*)begin
    spi_mode_next = spi_mode_present;
    case (spi_mode_present)
        SPI_RUN: begin
            if(~spe)begin
                spi_mode_next = SPI_WAIT;
            end else begin
                spi_mode_next = spi_mode_present;
            end
        end 
        SPI_WAIT: begin
            if(spiswai_o)begin
                spi_mode_next = SPI_STOP;
            end else if(spe)begin
                spi_mode_next = SPI_RUN;
            end else
                spi_mode_next = spi_mode_present;
        end
        SPI_STOP: begin
            if(~spiswai_o)begin
                spi_mode_next = SPI_WAIT;
            end else if(spe)begin
                spi_mode_next = SPI_RUN;
            end else
                spi_mode_next = spi_mode_present;
        end
        default: spi_mode_next = SPI_RUN;
    endcase

end


/*
always @(posedge PCLK or negedge PRESET_n)begin
    if(~PRESET_n)begin
        send_data_o <= 0;
    end else if(~wr_enb)begin
            if(SPI_DR != miso_data_i && ((spi_mode_o==SPI_RUN) || (spi_mode_o==SPI_WAIT)))begin
                    send_data_o <= 1;
            end else if(receive_data_i && ((spi_mode_o == SPI_RUN)||(spi_mode_o == SPI_WAIT)))begin
                    send_data_o <= 0;
            end else
                send_data_o <= send_data_o;
    end
end   */

always @(posedge PCLK or negedge PRESET_n)begin
    if(~PRESET_n)begin
        send_data_o <= 0;
    end else begin
            if(wr_enb && (PADDR_i == 3'b101) && ((spi_mode_o==SPI_RUN) || (spi_mode_o==SPI_WAIT)))begin
                    send_data_o <= 1;
            end else //if(~wr_enb && receive_data_i && ((spi_mode_o == SPI_RUN)||(spi_mode_o == SPI_WAIT)))begin
                    send_data_o <= 0;
           // end else
             //   send_data_o <= send_data_o;
    end
end 


always @(posedge PCLK or negedge PRESET_n) begin
    
    if(~PRESET_n)
        mosi_data_o <= 0;
    else if(wr_enb && (PADDR_i == 3'b101) && ((spi_mode_o==SPI_RUN) || (spi_mode_o==SPI_WAIT)))begin
        mosi_data_o <= PWDATA_i;
    end
end

/*
always @(posedge PCLK or negedge PRESET_n)begin
    if(~PRESET_n)begin
        mosi_data_o <= 0;
    end else if(~wr_enb)begin
        if(SPI_DR != miso_data_i && ((spi_mode_present == SPI_RUN)||(spi_mode_present == SPI_WAIT)))begin
            mosi_data_o <= SPI_DR;
        end
    end
end  */



endmodule