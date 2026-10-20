// Abstract Data Link transmit/replay controller for a bounded packet interface.
// The PHY-facing interface carries packet data, sequence number, and LCRC as
// separate fields. This is not a complete PCIe DLLP/PHY implementation.
module pcie_dll_replay #(
    parameter int unsigned MAX_PACKET_BYTES = 16,
    parameter int unsigned SEQ_WIDTH        = 12
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 tlp_valid,
    output logic                 tlp_ready,
    input  logic [127:0]         tlp_data,
    input  logic [4:0]           tlp_bytes,
    output logic                 link_valid,
    input  logic                 link_ready,
    output logic [SEQ_WIDTH-1:0] link_seq,
    output logic [127:0]         link_data,
    output logic [4:0]           link_bytes,
    output logic [31:0]          link_lcrc,
    input  logic                 ack_valid,
    input  logic [SEQ_WIDTH-1:0] ack_seq,
    input  logic                 nak_valid,
    input  logic [SEQ_WIDTH-1:0] nak_seq,
    input  logic                 replay_timeout,
    output logic                 outstanding
);

    logic [SEQ_WIDTH-1:0] next_seq;
    logic [SEQ_WIDTH-1:0] saved_seq;
    logic [127:0]         saved_data;
    logic [4:0]           saved_bytes;
    logic [31:0]          saved_lcrc;
    logic                 pending_send;
    logic                 awaiting_ack;
    logic [31:0]          computed_lcrc;
    logic [127:0]         crc_data;
    logic [4:0]           crc_bytes;

    pcie_lcrc32 crc_unit (
        .packet_data  (crc_data),
        .packet_bytes (crc_bytes),
        .lcrc         (computed_lcrc)
    );

    assign tlp_ready   = rst_n && !outstanding;
    assign link_valid  = rst_n && pending_send;
    assign link_seq    = saved_seq;
    assign link_data   = saved_data;
    assign link_bytes  = saved_bytes;
    assign link_lcrc   = saved_lcrc;
    assign outstanding = pending_send || awaiting_ack;

    always_comb begin
        crc_data  = tlp_data;
        crc_bytes = tlp_bytes;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_seq     <= '0;
            saved_seq    <= '0;
            saved_data   <= '0;
            saved_bytes  <= '0;
            saved_lcrc   <= '0;
            pending_send <= 1'b0;
            awaiting_ack <= 1'b0;
        end
        else begin
            if (tlp_valid && tlp_ready &&
                (tlp_bytes != 0) && (tlp_bytes <= MAX_PACKET_BYTES)) begin
                saved_seq    <= next_seq;
                saved_data   <= tlp_data;
                saved_bytes  <= tlp_bytes;
                saved_lcrc   <= computed_lcrc;
                pending_send <= 1'b1;
                awaiting_ack <= 1'b0;
            end

            if (pending_send && link_ready) begin
                pending_send <= 1'b0;
                awaiting_ack <= 1'b1;
            end

            if (ack_valid && awaiting_ack && (ack_seq == saved_seq)) begin
                awaiting_ack <= 1'b0;
                next_seq <= next_seq + {{(SEQ_WIDTH-1){1'b0}}, 1'b1};
            end

            if (((nak_valid && (nak_seq == saved_seq)) || replay_timeout) &&
                awaiting_ack) begin
                pending_send <= 1'b1;
                awaiting_ack <= 1'b0;
            end
        end
    end

`ifndef SYNTHESIS
    property p_packet_stable_while_link_stalled;
        @(posedge clk) disable iff (!rst_n)
            link_valid && !link_ready
            |=> link_valid &&
                $stable({link_seq, link_data, link_bytes, link_lcrc});
    endproperty

    assert property (p_packet_stable_while_link_stalled)
        else $error("Data Link packet changed while stalled");

    property p_no_new_packet_while_outstanding;
        @(posedge clk) disable iff (!rst_n)
            outstanding |-> !tlp_ready;
    endproperty

    assert property (p_no_new_packet_while_outstanding)
        else $error("New packet accepted while replay buffer occupied");
`endif

endmodule