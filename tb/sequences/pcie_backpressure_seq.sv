class pcie_backpressure_seq extends pcie_base_seq;
    `uvm_object_utils(pcie_backpressure_seq)

    function new(string name = "pcie_backpressure_seq");
        super.new(name);
    endfunction

    task body();
        send_tx(PCIE_OP_MEM_WRITE, 32'h1000, 32'h1357_9BDF, 4'hF, 8'h70, 0);
        send_tx(PCIE_OP_MEM_READ,  32'h1000, 0,             4'hF, 8'h71, 1);
        send_tx(PCIE_OP_MEM_READ,  32'h1000, 0,             4'hF, 8'h72, 4);
        send_tx(PCIE_OP_MEM_READ,  32'h1000, 0,             4'hF, 8'h73, 8);
        send_tx(PCIE_OP_MEM_WRITE, 32'h1004, 32'h2468_ACE0, 4'hF, 8'h74, 3);
        send_tx(PCIE_OP_MEM_READ,  32'h1004, 0,             4'hF, 8'h75, 6);
    endtask

endclass
