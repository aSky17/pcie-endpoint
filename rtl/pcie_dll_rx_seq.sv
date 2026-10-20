// Receive-side sequence checker and duplicate suppression for a single abstract stream.
// expected_sequence advances only on an accepted in-order packet. A duplicate
// previous sequence is acknowledged as duplicate but not delivered twice.
module pcie_dll_rx_seq #(
    parameter int unsigned SEQ_WIDTH = 12
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 rx_valid,
    input  logic [SEQ_WIDTH-1:0] rx_sequence,
    input  logic                 rx_integrity_ok,
    output logic                 rx_accept,
    output logic                 rx_duplicate,
    output logic                 rx_nak,
    output logic [SEQ_WIDTH-1:0] expected_sequence
);

    logic [SEQ_WIDTH-1:0] last_accepted;
    logic                 have_last;

    always_comb begin
        rx_accept    = 1'b0;
        rx_duplicate = 1'b0;
        rx_nak       = 1'b0;

        if (rx_valid) begin
            if (!rx_integrity_ok)
                rx_nak = 1'b1;
            else if (rx_sequence == expected_sequence)
                rx_accept = 1'b1;
            else if (have_last && rx_sequence == last_accepted)
                rx_duplicate = 1'b1;
            else
                rx_nak = 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expected_sequence <= '0;
            last_accepted     <= '0;
            have_last         <= 1'b0;
        end
        else if (rx_valid && rx_accept) begin
            last_accepted     <= rx_sequence;
            expected_sequence <= expected_sequence + {{(SEQ_WIDTH-1){1'b0}}, 1'b1};
            have_last         <= 1'b1;
        end
    end

endmodule