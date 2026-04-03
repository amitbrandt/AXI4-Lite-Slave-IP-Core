`timescale 1ns / 1ps

module axi_lite_slave_tb();

    // -- Testbench Signals ----------------------------------------------------
    reg         clk;
    reg         rst_n;
    
    // Write Channels
    reg [31:0]  awaddr;
    reg         awvalid;
    wire        awready;
    reg [31:0]  wdata;
    reg         wvalid;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;
    
    // Read Channels
    reg [31:0]  araddr;
    reg         arvalid;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;

    // -- Instantiate Unit Under Test (UUT) ------------------------------------
    axi_lite_slave uut (
        .S_AXI_ACLK(clk),
        .S_AXI_ARESETN(rst_n),
        .S_AXI_AWADDR(awaddr),
        .S_AXI_AWVALID(awvalid),
        .S_AXI_AWREADY(awready),
        .S_AXI_WDATA(wdata),
        .S_AXI_WVALID(wvalid),
        .S_AXI_WREADY(wready),
        .S_AXI_BRESP(bresp),
        .S_AXI_BVALID(bvalid),
        .S_AXI_BREADY(bready),
        .S_AXI_ARADDR(araddr),
        .S_AXI_ARVALID(arvalid),
        .S_AXI_ARREADY(arready),
        .S_AXI_RDATA(rdata),
        .S_AXI_RRESP(rresp),
        .S_AXI_RVALID(rvalid),
        .S_AXI_RREADY(rready)
    );

    // -- Clock Generation (100MHz) --------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk; // 10ns period

    // -- AXI Write Task -------------------------------------------------------
    task axi_write(input [31:0] addr, input [31:0] data);
    begin
        @(posedge clk);
        awaddr = addr;
        awvalid = 1;
        wdata = data;
        wvalid = 1;
        bready = 1;
        
        // Wait for Slave to be ready
        wait (awready && wready);
        @(posedge clk);
        awvalid = 0;
        wvalid = 0;
        
        // Wait for Response
        wait (bvalid);
        @(posedge clk);
        bready = 0;
        $display("[WRITE] Address: 0x%h, Data: 0x%h", addr, data);
    end
    endtask

    // -- AXI Read Task --------------------------------------------------------
    task axi_read(input [31:0] addr);
    begin
        @(posedge clk);
        araddr = addr;
        arvalid = 1;
        rready = 1;
        
        wait (arready);
        @(posedge clk);
        arvalid = 0;
        
        wait (rvalid);
        @(posedge clk);
        rready = 0;
        $display("[READ] Address: 0x%h, Received Data: 0x%h", addr, rdata);
    end
    endtask

    // -- Main Test Stimulus ---------------------------------------------------
    initial begin
        // Initial values
        rst_n = 0;
        awaddr = 0; awvalid = 0; wdata = 0; wvalid = 0; bready = 0;
        araddr = 0; arvalid = 0; rready = 0;
        
        // Reset sequence
        #20 rst_n = 1;
        #10;

        // Test 1: Write to slv_reg0 (Address 0x0)
        axi_write(32'h00000000, 32'hDEADBEEF);
        
        // Test 2: Write to slv_reg1 (Address 0x4)
        axi_write(32'h00000004, 32'h12345678);
        
        // Test 3: Read back from slv_reg0
        axi_read(32'h00000000);
        
        // Test 4: Read back from slv_reg1
        axi_read(32'h00000004);

        #100;
        $display("Simulation Finished Successfully!");
        $finish;
    end

endmodule