// Tracks split Completion progress for one Tag. The surrounding requester is
// responsible for allocating Tags and decoding Completion headers/payloads.
module pcie_completion_assembler #(
    parameter int unsigned TAG_COUNT = 32,
    parameter int unsigned TAG_WIDTH = $clog2(TAG_COUNT)
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 req_valid,
    output logic                 req_ready,
    input  logic [TAG_WIDTH-1:0] req_tag,
    input  logic [15:0]          req_requester_id,
    input  logic [11:0]          req_total_bytes,
    input  logic [6:0]           req_lower_address,
    input  logic                 cpl_valid,
    input  logic [TAG_WIDTH-1:0] cpl_tag,
    input  logic [15:0]          cpl_requester_id,
    input  logic [2:0]           cpl_status,
    input  logic [11:0]          cpl_byte_count,
    input  logic [6:0]           cpl_lower_address,
    input  logic [12:0]          cpl_payload_bytes,
    output logic                 cpl_accept,
    output logic                 cpl_error,
    output logic [3:0]           cpl_error_code,
    output logic                 request_done,
    output logic [11:0]          bytes_remaining,
    output logic [TAG_COUNT-1:0] outstanding_bitmap
);

    localparam logic [3:0] ERR_TAG        = 4'd1,
                         ERR_UNEXPECTED  = 4'd2,
                         ERR_REQUESTER   = 4'd3,
                         ERR_BYTE_COUNT  = 4'd4,
                         ERR_LOWER_ADDR  = 4'd5,
                         ERR_PAYLOAD     = 4'd6,
                         ERR_STATUS      = 4'd7;

    logic [TAG_COUNT-1:0] active_q;
    logic [15:0]          requester_q [0:TAG_COUNT-1];
    logic [11:0]          remaining_q [0:TAG_COUNT-1];
    logic [6:0]           lower_q [0:TAG_COUNT-1];
    logic [TAG_COUNT-1:0] active_next;
    logic [11:0]          after_bytes;
    integer               i;

    always_comb begin
        outstanding_bitmap = active_q;
        req_ready           = 1'b0;

        if (req_tag < TAG_COUNT)
            req_ready = !active_q[req_tag] && (req_total_bytes != 0);

        cpl_accept     = 1'b0;
        cpl_error      = 1'b0;
        cpl_error_code = 4'd0;
        request_done   = 1'b0;
        bytes_remaining = '0;
        after_bytes     = '0;

        if (cpl_valid) begin
            if (cpl_tag >= TAG_COUNT) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_TAG;
            end
            else if (!active_q[cpl_tag]) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_UNEXPECTED;
            end
            else if (cpl_requester_id != requester_q[cpl_tag]) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_REQUESTER;
            end
            else if (!(cpl_status inside {3'b000, 3'b001, 3'b010, 3'b100})) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_STATUS;
            end
            else if (cpl_status != 3'b000) begin
                cpl_accept   = 1'b1;
                request_done = 1'b1;
            end
            else if (cpl_byte_count != remaining_q[cpl_tag]) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_BYTE_COUNT;
            end
            else if (cpl_lower_address != lower_q[cpl_tag]) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_LOWER_ADDR;
            end
            else if (cpl_payload_bytes == 0 ||
                     cpl_payload_bytes > remaining_q[cpl_tag]) begin
                cpl_error      = 1'b1;
                cpl_error_code = ERR_PAYLOAD;
            end
            else begin
                cpl_accept  = 1'b1;
                after_bytes = remaining_q[cpl_tag] - cpl_payload_bytes;
                request_done = (after_bytes == 0);
                bytes_remaining = after_bytes;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_q <= '0;

            for (i = 0; i < TAG_COUNT; i = i + 1) begin
                requester_q[i] <= '0;
                remaining_q[i] <= '0;
                lower_q[i]     <= '0;
            end
        end
        else begin
            if (cpl_valid && cpl_accept) begin
                if (request_done)
                    active_q[cpl_tag] <= 1'b0;
                else begin
                    remaining_q[cpl_tag] <= after_bytes;
                    lower_q[cpl_tag] <= lower_q[cpl_tag] + cpl_payload_bytes[6:0];
                end
            end

            if (req_valid && req_ready) begin
                active_q[req_tag]     <= 1'b1;
                requester_q[req_tag]  <= req_requester_id;
                remaining_q[req_tag]  <= req_total_bytes;
                lower_q[req_tag]      <= req_lower_address;
            end
        end
    end

endmodule