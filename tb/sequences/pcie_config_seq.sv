class pcie_config_seq extends pcie_base_seq;
    `uvm_object_utils(pcie_config_seq)

    function new(string name = "pcie_config_seq");
        super.new(name);
    endfunction

    task body();
        send_tx(PCIE_OP_CFG_READ,  32'h00, 0,             4'hF, 8'h10);
        send_tx(PCIE_OP_CFG_READ,  32'h04, 0,             4'hF, 8'h11);
        send_tx(PCIE_OP_CFG_READ,  32'h08, 0,             4'hF, 8'h12);
        send_tx(PCIE_OP_CFG_READ,  32'h34, 0,             4'hF, 8'h13);
        send_tx(PCIE_OP_CFG_READ,  32'h40, 0,             4'hF, 8'h14);
        send_tx(PCIE_OP_CFG_WRITE, 32'h48, 32'h0000_ABCD, 4'h3, 8'h15);
        send_tx(PCIE_OP_CFG_READ,  32'h48, 0,             4'hF, 8'h16);
        send_tx(PCIE_OP_CFG_WRITE, 32'h10, 32'hFFFF_FFFF, 4'hF, 8'h17);
        send_tx(PCIE_OP_CFG_READ,  32'h10, 0,             4'hF, 8'h18);
        send_tx(PCIE_OP_CFG_WRITE, 32'h10, 32'h0000_1000, 4'hF, 8'h19);
        send_tx(PCIE_OP_CFG_READ,  32'h10, 0,             4'hF, 8'h1A);
    endtask

endclass
