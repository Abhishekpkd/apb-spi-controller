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
reg latched_send_data, sr_read;

reg spif,sptef;
wire modf,modfen;
wire spie,spe,sptie;
wire wr_enb,rd_enb,apb_access, transfer_done;    
wire SSOE, valid_working_mode;

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

//SPI_SR
always @(posedge PCLK or negedge PRESET_n)begin
 if(~PRESET_n) begin
    SPI_SR <= 8'h20;
    spif  <= 0;
    sptef <= 1;
    sr_read <= 0;
 end else begin
        if(receive_data_i)begin
            spif <= 1;  //transfer completed new data available
        end 

        if(rd_enb && PADDR_i == 3'b011)begin
            sr_read <= 1;
        end 
        if(rd_enb && PADDR_i == 3'b101 && sr_read) begin
            spif <= 0;    // data read by cpu can transfer new data
            sr_read <= 0;
        end

        if(send_data_o)
            latched_send_data <= send_data_o;

        if(wr_enb && (PADDR_i == 3'b101))begin
            sptef <= 0;     //buffer full
        end else if(latched_send_data)begin   // && ~tip_i)begin   // transfer finished
            sptef <= 1;     //buffer empty
            latched_send_data <= 0;
        end

        SPI_SR <= {spif,1'b0,sptef,modf,4'b0};
    end
end



assign transfer_done = (apb_present_state == ENABLE) && PREADY_o;

assign wr_enb = transfer_done && PWRITE_i;
assign rd_enb = transfer_done && ~PWRITE_i;

assign spi_interrupt_request_o = (~spie && ~sptie) ? 0 :
    ((spie && ~sptie)&&(spif || modf)) ? 1 :
        ((~spie && sptie) && sptef) ? 1 :
            (sptef||modf||spif);

assign spi_mode_o = spi_mode_present;

 
always @(posedge PCLK or negedge PRESET_n)begin: APB_FSM_PRESENT
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
            if(!PREADY_o) begin
                apb_next_state = apb_present_state;
            end else if(PSEL_i && ~PENABLE_i)begin
                apb_next_state = SETUP;
            end else begin
                apb_next_state = IDLE;
            end
        end
        default: apb_next_state = IDLE;
    endcase
end  



    always @(*) begin
    PREADY_o = 0;
    PSLVERR_o = 0;

    if(apb_present_state == ENABLE) begin

        // WRITE to SPI_DR
        if(PWRITE_i && (PADDR_i == 3'b101)) begin
            PREADY_o = sptef;   // wait if TX busy buffer not empty
        end

        // READ from SPI_DR
        else if(~PWRITE_i && (PADDR_i == 3'b101)) begin
            PREADY_o = spif;    // wait if RX not ready
        end

        // other registers
        else if (PADDR_i != 3'b101)begin
            PREADY_o = 1;
        end else 
            PREADY_o = 0;

        PSLVERR_o = (PADDR_i > 3'b101);
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
    end else if(receive_data_i)begin     // if wr_enb and receive both high receive first from pereferal miso
        latched_receive_data <= 1;
    end else if(latched_receive_data) begin
        SPI_DR <= miso_data_i;
        latched_receive_data <= 0;
    end else if(wr_enb && (PADDR_i == 3'b101))begin
        SPI_DR <= PWDATA_i;
    end
end



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
            end 
        end 
        SPI_WAIT: begin
            if(spe)begin
                spi_mode_next = SPI_RUN;
            end else if(spiswai_o)begin
                spi_mode_next = SPI_STOP;
            end 
        end
        SPI_STOP: begin
            if(spe)begin
                spi_mode_next = SPI_RUN;
            end else if(~spiswai_o)begin
                spi_mode_next = SPI_WAIT;
            end 
        end
        default: spi_mode_next = SPI_RUN;
    endcase

end


reg tx_pending;
always @(posedge PCLK or negedge PRESET_n) begin
    if(~PRESET_n)
        tx_pending <= 0;
    else if(wr_enb && PADDR_i == 3'b101)
        tx_pending <= 1;
    else if(send_data_o && ~wr_enb)
        tx_pending <= 0;
end

//reg wr_enb_hold;
assign valid_working_mode = ((spi_mode_o==SPI_RUN) || ((spi_mode_o==SPI_WAIT) && ~spiswai_o ));
always @(posedge PCLK or negedge PRESET_n)begin
    if(~PRESET_n)begin
        send_data_o <= 0;
    end else if(wr_enb && PADDR_i == 3'b101 && ~tip_i && valid_working_mode)begin
                send_data_o <= 1;
    end else if(tx_pending && ~tip_i && valid_working_mode)begin
                send_data_o <= 1;
    end else if(tip_i)begin
                send_data_o <= 0;
    end else 
                send_data_o <= send_data_o;
end 

reg cycle_delay=0;
always @(posedge PCLK or negedge PRESET_n) begin
    
    if(~PRESET_n)
        mosi_data_o <= 0;
    else if(wr_enb && (PADDR_i == 3'b101) && ~tip_i && valid_working_mode)begin
        mosi_data_o <= PWDATA_i;
    end else if(wr_enb && (PADDR_i == 3'b101) && tip_i && valid_working_mode)begin
        cycle_delay <= 1;
    end else if(cycle_delay)begin
        mosi_data_o <= SPI_DR;
        cycle_delay <= 0;
    end
end




endmodule