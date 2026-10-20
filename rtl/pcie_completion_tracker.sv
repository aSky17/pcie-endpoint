// Completion association table for an abstract PCIe requester.
// Tracks outstanding non-posted requests by Tag and validates received
// Completion identity and byte-count metadata. Payload assembly and PCIe
// split-Completion policy remain the responsibility of the caller.
module pcie_completion_tracker #(
    parameter int unsigned TAG_COUNT = 32,
    parameter int unsigned TAG_WIDTH = $clog2(TAG_COUNT)
) (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            req_valid,
    output logic                            req_ready,
    input  logic [TAG_WIDTH-1:0]            req_tag,
    input  logic [15:0]                     req_requester_id,
    input  logic [11:0]                     req_expected_bytes,
    input  logic [6:0]                      req_lower_address,
    input  logic                            cpl_valid,
    input  logic [TAG_WIDTH-1:0]            cpl_tag,
    input  logic [15:0]                     cpl_requester_id,
    input  logic [2:0]                      cpl_status,
    input  logic [11:0]                     cpl_byte_count,
    input  logic [6:0]                      cpl_lower_address,
    output logic                            cpl_match,
    output logic                            cpl_error,
    output logic [3:0]                      cpl_error_code,
    output logic [TAG_COUNT-1:0]             outstanding_bitmap,
    output logic [$clog2(TAG_COUNT+1)-1:0]  outstanding_count
);

    localparam logic [3:0] ERR_NONE       = 4'd0;
    localparam logic [3:0] ERR_TAG_RANGE  = 4'd1;
    localparam logic [3:0] ERR_UNEXPECTED = 4'd2;
    localparam logic [3:0] ERR_REQUESTER  = 4'd3;
    localparam logic [3:0] ERR_BYTE_COUNT = 4'd4;
    localparam logic [3:0] ERR_LOWER_ADDR = 4'd5;
    localparam logic [3:0] ERR_STATUS     = 4'd6;

    logic [15:0]          requester_id_q [0:TAG_COUNT-1];
    logic [11:0]          expected_bytes_q [0:TAG_COUNT-1];
    logic [6:0]           lower_address_q [0:TAG_COUNT-1];
    logic [TAG_COUNT-1:0] outstanding_q;
    integer               i;

    always_comb begin
        req_ready = 1'b0;

        if (req_tag < TAG_COUNT)
            req_ready = !outstanding_q[req_tag] ||
                        (cpl_valid && cpl_match && (cpl_tag == req_tag) &&
                         (cpl_requester_id == req_requester_id));

        outstanding_bitmap = outstanding_q;
        outstanding_count  = '0;

        for (integer k = 0; k < TAG_COUNT; k++)
            outstanding_count = outstanding_count + outstanding_q[k];

        cpl_match      = 1'b0;
        cpl_error      = 1'b0;
        cpl_error_code = ERR_NONE;

        if (cpl_valid) begin
            if (cpl_tag >= TAG_COUNT) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_TAG_RANGE;
            end
            else if (!outstanding_q[cpl_tag]) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_UNEXPECTED;
            end
            else if (cpl_requester_id != requester_id_q[cpl_tag]) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_REQUESTER;
            end
            else if (cpl_status == 3'b000 &&
                     cpl_byte_count != expected_bytes_q[cpl_tag]) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_BYTE_COUNT;
            end
            else if (cpl_status == 3'b000 &&
                     cpl_lower_address != lower_address_q[cpl_tag]) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_LOWER_ADDR;
            end
            else if (!(cpl_status inside {3'b000, 3'b001, 3'b010, 3'b100})) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_STATUS;
            end
            else begin
                cpl_match = 1'b1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            outstanding_q <= '0;

            for (i = 0; i < TAG_COUNT; i = i + 1) begin
                requester_id_q[i]  <= '0;
                expected_bytes_q[i] <= '0;
                lower_address_q[i] <= '0;
            end
        end
        else begin
            // Completion frees a slot only when every checked identity field is valid.
            if (cpl_valid && cpl_match)
                outstanding_q[cpl_tag] <= 1'b0;

            // Same-cycle completion and re-allocation of the same Tag is supported.
            if (req_valid && req_ready) begin
                outstanding_q[req_tag]  <= 1'b1;
                requester_id_q[req_tag] <= req_requester_id;
                expected_bytes_q[req_tag] <= req_expected_bytes;
                lower_address_q[req_tag] <= req_lower_address;
            end
        end
    end

`ifndef SYNTHESIS
    property p_request_tag_unique;
        @(posedge clk) disable iff (!rst_n)
            req_valid && req_ready |-> !outstanding_q[req_tag] ||
                (cpl_valid && cpl_match && cpl_tag == req_tag);
    endproperty

    assert property (p_request_tag_unique)
        else $error("Requester attempted to reuse an active PCIe Tag");
`endif

endmodule