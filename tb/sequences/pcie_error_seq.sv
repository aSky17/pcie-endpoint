class pcie_error_seq extends pcie_base_seq;
    `uvm_object_utils(pcie_error_seq)

    function new(string name = "pcie_error_seq");
        super.new(name);
    endfunction

    task body();
        send_tx(PCIE_OP_MEM_READ,  32'h2000, 0,             4'hF, 8'h60);
        send_tx(PCIE_OP_MEM_WRITE, 32'h2000, 32'hDEAD_BEEF, 4'hF, 8'h61);
        send_tx(PCIE_OP_MEM_READ,  32'h1001, 0,             4'hF, 8'h62);
        send_tx(PCIE_OP_CFG_WRITE, 32'h0000, 32'h0,         4'hF, 8'h63);
        send_tx(PCIE_OP_CFG_READ,  32'h0100, 0,             4'hF, 8'h64);
    endtask

endclass
