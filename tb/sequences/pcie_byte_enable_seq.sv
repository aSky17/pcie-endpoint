class pcie_byte_enable_seq extends pcie_base_seq;
    `uvm_object_utils(pcie_byte_enable_seq)

    function new(string name = "pcie_byte_enable_seq");
        super.new(name);
    endfunction

    task body();
        bit [3:0] be;

        send_tx(PCIE_OP_MEM_WRITE, 32'h1000, 32'h44332211, 4'hF, 8'h20);

        for (int unsigned n = 0; n < 16; n++) begin
            be = n[3:0];
            send_tx(PCIE_OP_MEM_WRITE, 32'h1000, 32'hA1B2C3D4 ^ (32'h01010101 * n),
                    be, (8'h21 + n[7:0]));
            send_tx(PCIE_OP_MEM_READ, 32'h1000, 0, 4'hF, (8'h41 + n[7:0]));
        end
    endtask

endclass
