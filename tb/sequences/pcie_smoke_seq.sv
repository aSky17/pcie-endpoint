class pcie_smoke_seq extends pcie_base_seq;
    `uvm_object_utils(pcie_smoke_seq)

    function new(string name = "pcie_smoke_seq");
        super.new(name);
    endfunction

    task body();
        send_tx(PCIE_OP_CFG_READ,  32'h0,    0,               4'hF,    8'h01);
        send_tx(PCIE_OP_MEM_WRITE, 32'h1000, 32'hA5C3_7E19,   4'hF,    8'h02);
        send_tx(PCIE_OP_MEM_READ,  32'h1000, 0,               4'hF,    8'h03);
        send_tx(PCIE_OP_MEM_WRITE, 32'h1000, 32'h0000_BB00,   4'b0010, 8'h04);
        send_tx(PCIE_OP_MEM_READ,  32'h1000, 0,               4'hF,    8'h05);
        send_tx(PCIE_OP_CFG_WRITE, 32'h0,    32'h0,           4'hF,    8'h06);
        send_tx(PCIE_OP_MEM_READ,  32'h2000, 0,               4'hF,    8'h07);
        send_tx(PCIE_OP_MEM_READ,  32'h1001, 0,               4'hF,    8'h08);
    endtask

endclass
