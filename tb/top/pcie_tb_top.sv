module pcie_tb_top;
    import uvm_pkg::*;
    import pcie_pkg::*;
    import pcie_tb_pkg::*;

    bit clk = 0;

    always #5ns clk = ~clk;

    pcie_packet_if pif(clk);

    pcie_endpoint #(
        .VENDOR_ID(16'h1D0F),
        .DEVICE_ID(16'hF001),
        .COMPLETER_ID(16'h0000),
        .BAR0_DWORDS(64)
    ) dut (
        pif
    );

    // Initialize the interface and start UVM at time zero.
    initial begin
        pif.rst_n            = 0;
        pif.req_valid        = 0;
        pif.req_op           = PCIE_OP_CFG_READ;
        pif.req_addr         = 0;
        pif.req_wdata        = 0;
        pif.req_be           = 4'hF;
        pif.req_tag          = 0;
        pif.req_requester_id = 16'h0100;
        pif.rsp_ready        = 0;

        uvm_config_db#(virtual pcie_packet_if)::set(
            null, "*", "vif", pif
        );

        run_test();
    end

    // Reset runs concurrently with the UVM phases.
    initial begin
        repeat (4) @(negedge clk);
        pif.rst_n = 1;
    end

endmodule
