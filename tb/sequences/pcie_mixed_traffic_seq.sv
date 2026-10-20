// Directed mixed-operation traffic to exercise operation/status/address/tag/stall crosses.
class pcie_mixed_traffic_seq extends pcie_base_seq;
    `uvm_object_utils(pcie_mixed_traffic_seq)

    function new(string name = "pcie_mixed_traffic_seq");
        super.new(name);
    endfunction

    task body();
        // Configuration space: reads and modeled writable-field accesses.
        send_tx(PCIE_OP_CFG_READ,  32'h0000, 0,              4'hF, 8'h03, 0);
        send_tx(PCIE_OP_CFG_READ,  32'h0010, 0,              4'hF, 8'h40, 1);
        send_tx(PCIE_OP_CFG_WRITE, 32'h0048, 32'h0000_005A,  4'h3, 8'h90, 3);
        send_tx(PCIE_OP_CFG_READ,  32'h0048, 0,              4'hF, 8'hF0, 6);

        // BAR0 first/interior/last DWORDs, with multiple byte-enable classes.
        send_tx(PCIE_OP_MEM_WRITE, 32'h1000, 32'h1020_3040, 4'hF, 8'h05, 0);
        send_tx(PCIE_OP_MEM_READ,  32'h1000, 0,              4'hF, 8'h45, 2);
        send_tx(PCIE_OP_MEM_WRITE, 32'h1080, 32'h5566_7788, 4'h5, 8'h95, 4);
        send_tx(PCIE_OP_MEM_READ,  32'h1080, 0,              4'hF, 8'hF5, 8);
        send_tx(PCIE_OP_MEM_WRITE, 32'h10FC, 32'hAABB_CCDD, 4'hA, 8'h0A, 1);
        send_tx(PCIE_OP_MEM_READ,  32'h10FC, 0,              4'hF, 8'h4A, 3);

        // Negative cases: outside BAR and unaligned address.
        send_tx(PCIE_OP_MEM_READ,  32'h1100, 0,              4'hF, 8'h9A, 0);
        send_tx(PCIE_OP_MEM_READ,  32'h1001, 0,              4'hF, 8'hFA, 5);
    endtask

endclass
