module pcie_endpoint #(
    parameter logic [15:0] VENDOR_ID    = 16'h1D0F,
    parameter logic [15:0] DEVICE_ID    = 16'hF001,
    parameter logic [15:0] COMPLETER_ID = 16'h0000,
    parameter int unsigned BAR0_DWORDS  = 64
) (pcie_packet_if.dut bus);

    import pcie_pkg::*;

    logic [31:0] cfg [0:PCIE_CFG_DWORDS-1];
    logic [31:0] bar0_mem [0:BAR0_DWORDS-1];

    logic [31:0] req_addr_q, req_wdata_q;
    logic [3:0]  req_be_q;
    logic [7:0]  req_tag_q;
    logic [15:0] req_requester_id_q;
    pcie_op_e    req_op_q;

    integer i;
    integer word_index;

    logic [31:0] read_value;
    logic [31:0] bar0_base;
    logic        bar0_probe;
    logic        request_error;

    pcie_cpl_status_e response_status;

    // Single-entry response buffer. A response may be consumed and a new request
    // accepted on the same rising edge.
    assign bus.req_ready = !bus.rsp_valid || bus.rsp_ready;
    assign bar0_base     = cfg[4] & 32'hFFFF_FF00;

    always_comb begin
        word_index     = -1;
        read_value     = 32'h0;
        request_error  = 1'b0;
        response_status = PCIE_CPL_SUCCESS;

        if (bus.req_addr[1:0] != 2'b00) begin
            request_error  = 1'b1;
            response_status = PCIE_CPL_MALFORMED;
        end else begin
            case (bus.req_op)
                PCIE_OP_CFG_READ, PCIE_OP_CFG_WRITE: begin
                    if ((bus.req_addr[31:12] != 20'h0) ||
                        (bus.req_addr[11:2] >= PCIE_CFG_DWORDS)) begin
                        request_error  = 1'b1;
                        response_status = PCIE_CPL_UR;
                    end else begin
                        word_index = bus.req_addr[7:2];
                        read_value = ((word_index == 4) && bar0_probe)
                                     ? ~(BAR0_DWORDS*4 - 1)
                                     : cfg[word_index];
                    end
                end

                PCIE_OP_MEM_READ, PCIE_OP_MEM_WRITE: begin
                    if ((bus.req_addr < bar0_base) ||
                        (bus.req_addr >= bar0_base + BAR0_DWORDS*4)) begin
                        request_error  = 1'b1;
                        response_status = PCIE_CPL_UR;
                    end else begin
                        word_index = (bus.req_addr - bar0_base) >> 2;
                        read_value = bar0_mem[word_index];
                    end
                end

                default: begin
                    request_error  = 1'b1;
                    response_status = PCIE_CPL_UR;
                end
            endcase
        end

        if ((bus.req_addr[1:0] == 2'b00) &&
            (bus.req_op == PCIE_OP_CFG_WRITE) &&
            (bus.req_addr[31:8] == 24'h0) &&
            (bus.req_addr[7:2] == 6'd0)) begin
            request_error  = 1'b1;
            response_status = PCIE_CPL_CA;
        end
    end

    always_ff @(posedge bus.clk or negedge bus.rst_n) begin
        if (!bus.rst_n) begin
            bus.rsp_valid         <= 1'b0;
            bus.rsp_op            <= PCIE_OP_UNSUPPORTED;
            bus.rsp_rdata          <= '0;
            bus.rsp_tag            <= '0;
            bus.rsp_requester_id   <= '0;
            bus.rsp_completer_id   <= COMPLETER_ID;
            bus.rsp_status         <= PCIE_CPL_SUCCESS;
            bus.rsp_byte_count     <= 4'd4;

            for (i = 0; i < PCIE_CFG_DWORDS; i = i + 1)
                cfg[i] <= 32'h0;

            cfg[0]  <= {DEVICE_ID, VENDOR_ID};
            cfg[1]  <= 32'h0010_0000;
            cfg[2]  <= 32'h0600_0000;
            cfg[3]  <= 32'h0000_0000;
            cfg[4]  <= PCIE_BAR0_BASE;
            cfg[13] <= 32'h0000_0040;
            cfg[16] <= 32'h0002_0010;
            cfg[17] <= 32'h0000_0000;
            cfg[18] <= 32'h0000_0000;

            bar0_probe <= 1'b0;

            for (i = 0; i < BAR0_DWORDS; i = i + 1)
                bar0_mem[i] <= 32'h0;
        end else begin
            if (bus.rsp_valid && bus.rsp_ready)
                bus.rsp_valid <= 1'b0;

            if (bus.req_valid && bus.req_ready) begin
                bus.rsp_valid       <= 1'b1;
                bus.rsp_op          <= bus.req_op;
                bus.rsp_tag         <= bus.req_tag;
                bus.rsp_requester_id <= bus.req_requester_id;
                bus.rsp_completer_id <= COMPLETER_ID;
                bus.rsp_byte_count   <= 4'd4;
                bus.rsp_status       <= response_status;
                bus.rsp_rdata        <= (request_error ||
                                         bus.req_op == PCIE_OP_MEM_WRITE ||
                                         bus.req_op == PCIE_OP_CFG_WRITE)
                                        ? 32'h0
                                        : read_value;

                if (!request_error) begin
                    case (bus.req_op)
                        PCIE_OP_CFG_WRITE: begin
                            case (bus.req_addr[7:2])
                                6'd1: begin
                                    for (int b = 0; b < 2; b++)
                                        if (bus.req_be[b])
                                            cfg[1][8*b +: 8] <= bus.req_wdata[8*b +: 8];
                                end

                                6'd4: begin
                                    if (bus.req_be == 4'hF &&
                                        bus.req_wdata == 32'hFFFF_FFFF) begin
                                        bar0_probe <= 1'b1;
                                    end else begin
                                        bar0_probe <= 1'b0;
                                        cfg[4][7:0] <= 8'h00;

                                        for (int b = 1; b < 4; b++)
                                            if (bus.req_be[b])
                                                cfg[4][8*b +: 8] <= bus.req_wdata[8*b +: 8];
                                    end
                                end

                                6'd18: begin
                                    for (int b = 0; b < 2; b++)
                                        if (bus.req_be[b])
                                            cfg[18][8*b +: 8] <= bus.req_wdata[8*b +: 8];
                                end

                                default: ;
                            endcase
                        end

                        PCIE_OP_MEM_WRITE: begin
                            for (int b = 0; b < 4; b++)
                                if (bus.req_be[b])
                                    bar0_mem[(bus.req_addr-bar0_base)>>2][8*b +: 8]
                                        <= bus.req_wdata[8*b +: 8];
                        end

                        default: ;
                    endcase
                end
            end
        end
    end

`ifndef SYNTHESIS
    property p_response_stable_under_backpressure;
        @(posedge bus.clk) disable iff (!bus.rst_n)
        bus.rsp_valid && !bus.rsp_ready
        |=> bus.rsp_valid &&
            $stable({bus.rsp_op, bus.rsp_rdata, bus.rsp_tag,
                     bus.rsp_requester_id, bus.rsp_completer_id,
                     bus.rsp_status, bus.rsp_byte_count});
    endproperty

    assert property (p_response_stable_under_backpressure)
    else $error("PCIe response changed while backpressured");

    property p_no_unaligned_accepted_request;
        @(posedge bus.clk) disable iff (!bus.rst_n)
        bus.req_valid && bus.req_ready && (bus.req_addr[1:0] != 2'b00)
        |=> bus.rsp_valid && bus.rsp_status == PCIE_CPL_MALFORMED;
    endproperty

    assert property (p_no_unaligned_accepted_request)
    else $error("Unaligned request was not reported malformed");
`endif

endmodule