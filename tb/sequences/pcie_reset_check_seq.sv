class pcie_reset_check_seq extends pcie_base_seq;
    `uvm_object_utils(pcie_reset_check_seq)

    function new(string name = "pcie_reset_check_seq");
        super.new(name);
    endfunction

    task body();
        send_tx(PCIE_OP_MEM_READ, 32'h1000, 0, 4'hF, 8'h82);
        send_tx(PCIE_OP_CFG_READ, 32'h00,   0, 4'hF, 8'h83);
        send_tx(PCIE_OP_CFG_READ, 32'h48,   0, 4'hF, 8'h84);
    endtask

endclass
