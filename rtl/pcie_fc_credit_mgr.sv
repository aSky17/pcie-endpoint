// Credit accounting block for an abstract PCIe flow-control model.
// Credit initialization/update inputs are assumed to have been decoded from
// valid flow-control DLLPs by the surrounding Data Link logic.
module pcie_fc_credit_mgr (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       init_valid,
    input  logic [7:0] init_ph,
    input  logic [7:0] init_pd,
    input  logic [7:0] init_nph,
    input  logic [7:0] init_npd,
    input  logic [7:0] init_cplh,
    input  logic [7:0] init_cpld,

    input  logic       update_valid,
    input  logic [2:0] update_class,
    input  logic [7:0] update_header_credits,
    input  logic [7:0] update_data_credits,

    input  logic       tx_valid,
    input  logic [2:0] tx_class,
    input  logic [7:0] tx_data_dwords,

    output logic       tx_allowed,

    output logic [7:0] ph_credits,
    output logic [7:0] pd_credits,
    output logic [7:0] nph_credits,
    output logic [7:0] npd_credits,
    output logic [7:0] cplh_credits,
    output logic [7:0] cpld_credits,

    output logic       credit_error
);

    localparam logic [2:0] FC_POSTED     = 3'd0;
    localparam logic [2:0] FC_NONPOSTED  = 3'd1;
    localparam logic [2:0] FC_COMPLETION = 3'd2;

    always_comb begin
        tx_allowed = 1'b0;

        case (tx_class)
            FC_POSTED:
                tx_allowed = (ph_credits != 0) &&
                             (pd_credits >= tx_data_dwords);

            FC_NONPOSTED:
                tx_allowed = (nph_credits != 0) &&
                             (npd_credits >= tx_data_dwords);

            FC_COMPLETION:
                tx_allowed = (cplh_credits != 0) &&
                             (cpld_credits >= tx_data_dwords);

            default:
                tx_allowed = 1'b0;
        endcase

        credit_error = tx_valid && !tx_allowed;
    end

    logic [7:0] ph_next, pd_next;
    logic [7:0] nph_next, npd_next;
    logic [7:0] cplh_next, cpld_next;

    always_comb begin
        ph_next   = ph_credits;
        pd_next   = pd_credits;
        nph_next  = nph_credits;
        npd_next  = npd_credits;
        cplh_next = cplh_credits;
        cpld_next = cpld_credits;

        if (update_valid) begin
            case (update_class)
                FC_POSTED: begin
                    ph_next = ph_credits + update_header_credits;
                    pd_next = pd_credits + update_data_credits;
                end

                FC_NONPOSTED: begin
                    nph_next = nph_credits + update_header_credits;
                    npd_next = npd_credits + update_data_credits;
                end

                FC_COMPLETION: begin
                    cplh_next = cplh_credits + update_header_credits;
                    cpld_next = cpld_credits + update_data_credits;
                end

                default: ;
            endcase
        end

        if (tx_valid && tx_allowed) begin
            case (tx_class)
                FC_POSTED: begin
                    ph_next = ph_next - 1'b1;
                    pd_next = pd_next - tx_data_dwords;
                end

                FC_NONPOSTED: begin
                    nph_next = nph_next - 1'b1;
                    npd_next = npd_next - tx_data_dwords;
                end

                FC_COMPLETION: begin
                    cplh_next = cplh_next - 1'b1;
                    cpld_next = cpld_next - tx_data_dwords;
                end

                default: ;
            endcase
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ph_credits   <= 0;
            pd_credits   <= 0;
            nph_credits  <= 0;
            npd_credits  <= 0;
            cplh_credits <= 0;
            cpld_credits <= 0;
        end else if (init_valid) begin
            ph_credits   <= init_ph;
            pd_credits   <= init_pd;
            nph_credits  <= init_nph;
            npd_credits  <= init_npd;
            cplh_credits <= init_cplh;
            cpld_credits <= init_cpld;
        end else begin
            ph_credits   <= ph_next;
            pd_credits   <= pd_next;
            nph_credits  <= nph_next;
            npd_credits  <= npd_next;
            cplh_credits <= cplh_next;
            cpld_credits <= cpld_next;
        end
    end

`ifndef SYNTHESIS
    property p_no_credit_underflow;
        @(posedge clk) disable iff (!rst_n)
        tx_valid |-> tx_allowed;
    endproperty

    // This property is a design assertion; negative tests should drive tx_valid
    // with insufficient credits to verify that the checker detects the violation.
    assert property (p_no_credit_underflow)
    else $error("Transmission attempted without sufficient PCIe flow-control credits");
`endif

endmodule