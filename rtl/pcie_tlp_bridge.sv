// Bounded TLP-to-endpoint adapter.
// Supports only one-DWORD, 3-DW Memory Read/Write Requests. It is an explicit
// packet-level boundary: no PHY framing, DLLP transport, or full PCIe error
// message generation is modeled here.
module pcie_tlp_bridge #(
    parameter logic [15:0] COMPLETER_ID = 16'h0000
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        rx_valid,
    output logic        rx_ready,
    input  logic [95:0] rx_header,
    input  logic        rx_payload_valid,
    input  logic [31:0] rx_payload,
    output logic        tx_valid,
    input  logic        tx_ready,
    output logic [95:0] tx_header,
    output logic        tx_has_payload,
    output logic [31:0] tx_payload,
    output logic        error_event,
    pcie_packet_if.bridge bus
);

    import pcie_pkg::*;

    logic dec_supported, dec_write;
    logic cfg_supported, cfg_write;
    logic [15:0] cfg_requester_id, cfg_destination_id;
    logic [7:0]  cfg_tag;
    logic [3:0]  cfg_first_be;
    logic [11:0] cfg_register_offset;

    logic        request_is_config, request_supported, request_is_write;
    logic [15:0] request_requester_id;
    logic [7:0]  request_tag;
    logic [3:0]  request_first_be;
    logic [31:0] request_address;
    logic        request_has_data;

    logic [9:0]  dec_length;
    logic [15:0] dec_requester_id;
    logic [7:0]  dec_tag;
    logic [3:0]  dec_first_be, dec_last_be;
    logic [31:0] dec_address;

    logic        request_payload_ok;
    logic        request_fire;
    logic        busy;
    logic        posted_write_q;
    logic [6:0]  lower_address_q;
    logic [11:0] byte_count_q;

    logic [2:0]  cpl_status;
    logic        cpl_encode_supported;
    logic [9:0]  cpl_length;
    logic [15:0] cpl_completer_id;
    logic [2:0]  cpl_status_in;
    logic [11:0] cpl_byte_count;
    logic [15:0] cpl_requester_id;
    logic [7:0]  cpl_tag;
    logic [6:0]  cpl_lower_address;

    logic [2:0] enabled_byte_count;
    logic [2:0] first_enabled_lane;
    logic       request_read_q;

    pcie_tlp_codec req_codec (
        .encode_valid(1'b0),
        .encode_write(1'b0),
        .encode_length_dw(10'd0),
        .encode_requester_id(16'd0),
        .encode_tag(8'd0),
        .encode_first_be(4'd0),
        .encode_last_be(4'd0),
        .encode_address(32'd0),
        .encode_supported(),
        .encoded_header(),
        .decode_header(rx_header),
        .decode_supported(dec_supported),
        .decode_write(dec_write),
        .decode_length_dw(dec_length),
        .decode_requester_id(dec_requester_id),
        .decode_tag(dec_tag),
        .decode_first_be(dec_first_be),
        .decode_last_be(dec_last_be),
        .decode_address(dec_address)
    );

    pcie_config_tlp_decoder cfg_codec (
        .header(rx_header),
        .supported(cfg_supported),
        .is_write(cfg_write),
        .requester_id(cfg_requester_id),
        .tag(cfg_tag),
        .first_be(cfg_first_be),
        .destination_id(cfg_destination_id),
        .register_offset(cfg_register_offset)
    );

    always_comb begin
        request_is_config   = cfg_supported && (cfg_destination_id == COMPLETER_ID);
        request_supported   = dec_supported || request_is_config;
        request_is_write    = request_is_config ? cfg_write : dec_write;
        request_requester_id = request_is_config ? cfg_requester_id : dec_requester_id;
        request_tag         = request_is_config ? cfg_tag : dec_tag;
        request_first_be    = request_is_config ? cfg_first_be : dec_first_be;
        request_address     = request_is_config
                              ? {20'd0, cfg_register_offset}
                              : dec_address;
        request_has_data    = (dec_supported && dec_write) ||
                              (request_is_config && cfg_write);
    end

    always_comb begin
        enabled_byte_count = 0;
        first_enabled_lane = 0;

        for (integer j = 0; j < 4; j = j + 1) begin
            if (request_first_be[j]) begin
                enabled_byte_count = enabled_byte_count + 1'b1;

                if (enabled_byte_count == 1)
                    first_enabled_lane = j[2:0];
            end
        end
    end

    assign request_payload_ok = !request_has_data || rx_payload_valid;
    assign rx_ready = rst_n && !busy && bus.req_ready && request_payload_ok;
    assign request_fire = rx_valid && rx_ready;

    assign bus.req_valid = rx_valid && !busy && request_payload_ok;

    assign bus.req_op = dec_supported
                        ? (dec_write ? PCIE_OP_MEM_WRITE : PCIE_OP_MEM_READ)
                        : (request_is_config
                           ? (cfg_write ? PCIE_OP_CFG_WRITE : PCIE_OP_CFG_READ)
                           : PCIE_OP_UNSUPPORTED);

    assign bus.req_addr = request_address;
    assign bus.req_wdata = rx_payload;
    assign bus.req_be = request_first_be;
    assign bus.req_tag = request_tag;
    assign bus.req_requester_id = request_requester_id;

    // Successful posted writes are consumed internally and do not emit a
    // Completion TLP. Errors on posted writes are surfaced as error_event; a
    // complete PCIe ERR_* Message implementation is outside this bounded adapter.
    assign tx_valid = bus.rsp_valid && busy && !posted_write_q;
    assign tx_payload = tx_has_payload ? bus.rsp_rdata : 32'h0;
    assign bus.rsp_ready = busy && (posted_write_q || !tx_valid || tx_ready);

    always_comb begin
        case (bus.rsp_status)
            PCIE_CPL_SUCCESS: cpl_status = 3'b000;
            PCIE_CPL_UR:      cpl_status = 3'b001;
            PCIE_CPL_CA:      cpl_status = 3'b100;
            default:          cpl_status = 3'b001;
        endcase

        tx_has_payload = tx_valid &&
                         (bus.rsp_status == PCIE_CPL_SUCCESS) &&
                         request_read_q &&
                         !posted_write_q;

        cpl_length        = tx_has_payload ? 10'd1 : 10'd0;
        cpl_completer_id  = COMPLETER_ID;
        cpl_status_in     = cpl_status;
        cpl_byte_count    = byte_count_q;