class pcie_boundary_seq extends pcie_base_seq;
    `uvm_object_utils(pcie_boundary_seq)

    function new(string name = "pcie_boundary_seq");
        super.new(name);
    endfunction

    task body();
        // First, interior, and last legal DWORD of the modeled BAR0 window.
        send_tx(PCIE_OP_MEM_WRITE, 32'h1000, 32'h1122_3344, 4'hF, 8'h20, 0);
        send_tx(PCIE_OP_MEM_READ,  32'h1000, 0,             4'hF, 8'h21, 0);
        send_tx(PCIE_OP_MEM_WRITE, 32'h1080, 32'hA5C3_7E19, 4'hF, 8'h22, 1);
        send_tx(PCIE_OP_MEM_READ,  32'h1080, 0,             4'hF, 8'h23, 2);
        send_tx(PCIE_OP_MEM_WRITE, 32'h10FC, 32'hDEAD_BEEF, 4'hF, 8'h24, 3);
        send_tx(PCIE_OP_MEM_READ,  32'h10FC, 0,             4'hF, 8'h25, 4);

        // Sparse byte enables and readback, including zero-enable write.
        send_tx(PCIE_OP_MEM_WRITE, 32'h1004, 32'hAABB_CCDD, 4'h1, 8'h26, 0);
        send_tx(PCIE_OP_MEM_WRITE, 32'h1004, 32'h1122_3344, 4'hA, 8'h27, 0);
        send_tx(PCIE_OP_MEM_READ,  32'h1004, 0,             4'hF, 8'h28, 1);
        send_tx(PCIE_OP_MEM_WRITE, 32'h1004, 32'hFFFF_FFFF, 4'h0, 8'h29, 0);
        send_tx(PCIE_OP_MEM_READ,  32'h1004, 0,             4'hF, 8'h2A, 0);

        // First DWORD outside the BAR0 window.
        send_tx(PCIE_OP_MEM_READ,  32'h1100, 0,             4'hF, 8'h2B, 0);
        send_tx(PCIE_OP_MEM_WRITE, 32'h1100, 32'h1234_5678, 4'hF, 8'h2C, 0);
    endtask

endclass
