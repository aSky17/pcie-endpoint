class pcie_scoreboard extends uvm_component;
    `uvm_component_utils(pcie_scoreboard)

    uvm_analysis_imp #(pcie_tlp_item, pcie_scoreboard) analysis_export;
    bit [31:0] model_mem[longint unsigned];
    bit [31:0] model_cfg[longint unsigned];
    int unsigned checked, errors;
    bit bar0_probe_model;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction

    function void write(pcie_tlp_item tr);
        longint unsigned idx;
        bit [31:0] expected;

        checked++;

        if (tr.completer_id !== 16'h0000) begin
            `uvm_error("SB_CPLID", "Unexpected Completer ID");
            errors++;
        end

        if (tr.byte_count !== 4'd4) begin
            `uvm_error("SB_BC", "Unexpected byte count in packet-level subset");
            errors++;
        end

        case (tr.op)
            PCIE_OP_CFG_READ: begin
                idx = tr.addr >> 2;

                if ((tr.addr[1:0] != 2'b00) ||
                    (tr.addr[11:2] >= 64) ||
                    (tr.addr[31:12] != 0)) begin
                    if (tr.status != PCIE_CPL_UR &&
                        tr.status != PCIE_CPL_MALFORMED) begin
                        `uvm_error("SB_CFG_INVALID",
                            "Invalid configuration read did not report an error");
                        errors++;
                    end

                    if (tr.rdata !== 32'h0) begin
                        `uvm_error("SB_CFG_INVALID_DATA",
                            "Invalid configuration read returned nonzero data");
                        errors++;
                    end
                end else begin
                    if (idx == 0)
                        expected = 32'hF001_1D0F;
                    else if (idx == 1)
                        expected = 32'h0010_0000;
                    else if (idx == 2)
                        expected = 32'h0600_0000;
                    else if (idx == 3)
                        expected = 32'h0;
                    else if (idx == 4)
                        expected = bar0_probe_model ? 32'hFFFF_FF00 : 32'h0000_1000;
                    else if (idx == 13)
                        expected = 32'h0000_0040;
                    else if (idx == 16)
                        expected = 32'h0002_0010;
                    else
                        expected = model_cfg.exists(idx) ? model_cfg[idx] : 32'h0;

                    if (tr.status != PCIE_CPL_SUCCESS || tr.rdata !== expected) begin
                        `uvm_error("SB_CFG_READ",
                            $sformatf("CFG read addr=%08x expected=%08x got=%08x status=%0d",
                                      tr.addr, expected, tr.rdata, tr.status));
                        errors++;
                    end
                end
            end

            PCIE_OP_CFG_WRITE: begin
                if (tr.addr == 32'h10 && tr.status == PCIE_CPL_SUCCESS) begin
                    if (tr.byte_enable == 4'hF && tr.wdata == 32'hFFFF_FFFF)
                        bar0_probe_model = 1'b1;
                    else
                        bar0_probe_model = 1'b0;
                end

                if (tr.addr == 32'h48 && tr.status == PCIE_CPL_SUCCESS) begin
                    idx      = 18;
                    expected = model_cfg.exists(idx) ? model_cfg[idx] : 32'h0;

                    for (int b = 0; b < 2; b++)
                        if (tr.byte_enable[b])
                            expected[8*b +: 8] = tr.wdata[8*b +: 8];

                    model_cfg[idx] = expected;
                end

                if (tr.addr == 0 && tr.status != PCIE_CPL_CA) begin
                    `uvm_error("SB_CFG_RO",
                        "Write to Vendor/Device ID did not return CA");
                    errors++;
                end
            end

            PCIE_OP_MEM_WRITE: begin
                idx = tr.addr;

                if (tr.addr[1:0] != 2'b00) begin
                    if (tr.status != PCIE_CPL_MALFORMED) begin
                        `uvm_error("SB_MEM_WRITE_ALIGN",
                            "Unaligned write did not return malformed status");
                        errors++;
                    end
                end else if (tr.addr < PCIE_BAR0_BASE ||
                             tr.addr >= PCIE_BAR0_BASE + PCIE_BAR0_BYTES) begin
                    if (tr.status != PCIE_CPL_UR) begin
                        `uvm_error("SB_MEM_WRITE_UR",
                            "Unmapped BAR write did not return UR");
                        errors++;
                    end
                end else begin
                    expected = model_mem.exists(idx) ? model_mem[idx] : 32'h0;

                    for (int b = 0; b < 4; b++)
                        if (tr.byte_enable[b])
                            expected[8*b +: 8] = tr.wdata[8*b +: 8];

                    model_mem[idx] = expected;

                    if (tr.status != PCIE_CPL_SUCCESS) begin
                        `uvm_error("SB_MEM_WRITE", "Legal BAR write failed");
                        errors++;
                    end
                end
            end

            PCIE_OP_MEM_READ: begin
                idx = tr.addr;

                if (tr.addr[1:0] != 2'b00) begin
                    if (tr.status != PCIE_CPL_MALFORMED || tr.rdata !== 32'h0) begin
                        `uvm_error("SB_MEM_READ_ALIGN",
                            "Unaligned read response incorrect");
                        errors++;
                    end
                end else if (tr.addr < PCIE_BAR0_BASE ||
                             tr.addr >= PCIE_BAR0_BASE + PCIE_BAR0_BYTES) begin
                    if (tr.status != PCIE_CPL_UR || tr.rdata !== 32'h0) begin
                        `uvm_error("SB_MEM_READ_UR",
                            "Unmapped BAR read response incorrect");
                        errors++;
                    end
                end else begin
                    expected = model_mem.exists(idx) ? model_mem[idx] : 32'h0;

                    if (tr.status != PCIE_CPL_SUCCESS || tr.rdata !== expected) begin
                        `uvm_error("SB_MEM_READ",
                            $sformatf("MEM read addr=%08x expected=%08x got=%08x status=%0d",
                                      tr.addr, expected, tr.rdata, tr.status));
                        errors++;
                    end
                end
            end

            default: begin
                `uvm_error("SB_OP", "Unexpected operation in scoreboard");
                errors++;
            end
        endcase
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SB_SUMMARY",
            $sformatf("Transactions checked=%0d errors=%0d", checked, errors),
            UVM_LOW)

        if (errors != 0)
            `uvm_error("SB_FAIL", "Scoreboard reported errors")
    endfunction

endclass
