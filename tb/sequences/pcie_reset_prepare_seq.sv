class pcie_reset_prepare_seq extends pcie_base_seq;
    `uvm_object_utils(pcie_reset_prepare_seq)

    function new(string name = "pcie_reset_prepare_seq");
        super.new(name);
    endfunction

    task body();
        send_tx(PCIE_OP_MEM_WRITE, 32'h1000, 32'hCAFE_BABE, 4'hF, 8'h80);
        send_tx(PCIE_OP_CFG_WRITE, 32'h48,   32'h0000_1234, 4'h3, 8'h81);
    endtask

endclass
