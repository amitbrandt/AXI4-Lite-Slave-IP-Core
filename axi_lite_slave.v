// -----------------------------------------------------------------------------
// Module Name: axi_lite_slave
// Description: Complete AXI-Lite Slave with 4 registers (Write/Read logic).
// -----------------------------------------------------------------------------

module axi_lite_slave (
    // -- Global Clock and Reset -----------------------------------------------
    input  wire        S_AXI_ACLK,
    input  wire        S_AXI_ARESETN,

    // -- Write Address Channel (AW) -------------------------------------------
    input  wire [31:0] S_AXI_AWADDR,
    input  wire        S_AXI_AWVALID,
    output reg         S_AXI_AWREADY,

    // -- Write Data Channel (W) -----------------------------------------------
    input  wire [31:0] S_AXI_WDATA,
    input  wire        S_AXI_WVALID,
    output reg         S_AXI_WREADY,

    // -- Write Response Channel (B) -------------------------------------------
    output wire [1:0]  S_AXI_BRESP,
    output reg         S_AXI_BVALID,
    input  wire        S_AXI_BREADY,

    // -- Read Address Channel (AR) --------------------------------------------
    input  wire [31:0] S_AXI_ARADDR,
    input  wire        S_AXI_ARVALID,
    output reg         S_AXI_ARREADY,

    // -- Read Data Channel (R) ------------------------------------------------
    output reg  [31:0] S_AXI_RDATA,
    output wire [1:0]  S_AXI_RRESP,
    output reg         S_AXI_RVALID,
    input  wire        S_AXI_RREADY
);

    // -- Internal Registers ---------------------------------------------------
    reg [31:0] slv_reg0;
    reg [31:0] slv_reg1;
    reg [31:0] slv_reg2;
    reg [31:0] slv_reg3;

    // -- Internal Signals -----------------------------------------------------
    wire [1:0] reg_address_select;
    wire       slv_reg_wren;
    wire       slv_reg_rden;
    reg [31:0] reg_data_out;

    // -- Assignments ----------------------------------------------------------
    assign reg_address_select = S_AXI_AWADDR[3:2];
    assign slv_reg_wren = S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWREADY && S_AXI_AWVALID;
    assign slv_reg_rden = S_AXI_ARREADY && S_AXI_ARVALID && ~S_AXI_RVALID;
    
    assign S_AXI_BRESP = 2'b00; // OKAY
    assign S_AXI_RRESP = 2'b00; // OKAY

    // -- Write Address/Data Ready Generation ----------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
        end else begin
            // Address Ready
            if (~S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID)
                S_AXI_AWREADY <= 1'b1;
            else
                S_AXI_AWREADY <= 1'b0;

            // Data Ready
            if (~S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWVALID)
                S_AXI_WREADY <= 1'b1;
            else
                S_AXI_WREADY <= 1'b0;
        end
    end

    // -- Register Write Logic -------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 32'h0;
            slv_reg1 <= 32'h0;
            slv_reg2 <= 32'h0;
            slv_reg3 <= 32'h0;
        end else if (slv_reg_wren) begin
            case (reg_address_select)
                2'b00: slv_reg0 <= S_AXI_WDATA;
                2'b01: slv_reg1 <= S_AXI_WDATA;
                2'b10: slv_reg2 <= S_AXI_WDATA;
                2'b11: slv_reg3 <= S_AXI_WDATA;
                default: ; 
            endcase
        end
    end

    // -- Write Response Logic (BVALID) ----------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            S_AXI_BVALID <= 1'b0;
        end else begin
            if (slv_reg_wren && ~S_AXI_BVALID)
                S_AXI_BVALID <= 1'b1;
            else if (S_AXI_BREADY && S_AXI_BVALID)
                S_AXI_BVALID <= 1'b0;
        end
    end

    // -- Read Address Ready (ARREADY) Generation ------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            S_AXI_ARREADY <= 1'b0;
        end else begin
            if (~S_AXI_ARREADY && S_AXI_ARVALID)
                S_AXI_ARREADY <= 1'b1;
            else
                S_AXI_ARREADY <= 1'b0;
        end
    end

    // -- Read Register Selection (Mux) ----------------------------------------
    always @(*) begin
        case (S_AXI_ARADDR[3:2])
            2'b00   : reg_data_out = slv_reg0;
            2'b01   : reg_data_out = slv_reg1;
            2'b10   : reg_data_out = slv_reg2;
            2'b11   : reg_data_out = slv_reg3;
            default : reg_data_out = 32'h0;
        endcase
    end

    // -- Read Data and Valid (RVALID) Generation ------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            S_AXI_RVALID <= 1'b0;
            S_AXI_RDATA  <= 32'h0;
        end else begin
            if (slv_reg_rden) begin
                S_AXI_RVALID <= 1'b1;
                S_AXI_RDATA  <= reg_data_out;
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

endmodule