// Bounded 3-DW Completion/Completion-with-Data header codec.
// Payload handling and the full range of Completion encodings are separate.
module pcie_completion_codec (
    input  logic        encode_valid,
    input  logic        encode_has_data,
    input  logic [9:0]  encode_length_dw,
    input  logic [15:0] encode_completer_id,
    input  logic [2:0]  encode_status,
    input  logic [11:0] encode_byte_count,
    input  logic [15:0] encode_requester_id,
    input  logic [7:0]  encode_tag,
    input  logic [6:0]  encode_lower_address,
    output logic        encode_supported,
    output logic [95:0] encoded_header,
    input  logic [95:0] decode_header,
    output logic        decode_supported,
    output logic        decode_has_data,
    output logic [9:0]  decode_length_dw,
    output logic [15:0] decode_completer_id,
    output logic [2:0]  decode_status,
    output logic [11:0] decode_byte_count,
    output logic [15:0] decode_requester_id,
    output logic [7:0]  decode_tag,
    output logic [6:0]  decode_lower_address
);

    logic [31:0] enc_dw0, enc_dw1, enc_dw2;
    logic [31:0] dec_dw0, dec_dw1, dec_dw2;
    logic [2:0]  fmt;
    logic [4:0]  tlp_type;

    always_comb begin
        enc_dw0         = 32'h0;
        enc_dw1         = 32'h0;
        enc_dw2         = 32'h0;
        encoded_header  = '0;

        encode_supported = encode_valid &&
                           ((encode_has_data && encode_length_dw == 10'd1) ||
                            (!encode_has_data && encode_length_dw == 10'd0));

        if (encode_supported) begin
            enc_dw0[31:29] = encode_has_data ? 3'b010 : 3'b000;
            enc_dw0[28:24] = 5'b01010;
            enc_dw0[9:0]   = encode_length_dw;

            enc_dw1[31:16] = encode_completer_id;
            enc_dw1[15:13] = encode_status;
            enc_dw1[12]    = 1'b0;
            enc_dw1[11:0]  = encode_byte_count;

            enc_dw2[31:16] = encode_requester_id;
            enc_dw2[15:8]  = encode_tag;
            enc_dw2[6:0]   = encode_lower_address;

            encoded_header = {enc_dw0, enc_dw1, enc_dw2};
        end
    end

    always_comb begin
        dec_dw0 = decode_header[95:64];
        dec_dw1 = decode_header[63:32];
        dec_dw2 = decode_header[31:0];

        fmt     = dec_dw0[31:29];
        tlp_type = dec_dw0[28:24];

        decode_has_data      = (fmt == 3'b010);
        decode_length_dw     = dec_dw0[9:0];
        decode_completer_id  = dec_dw1[31:16];
        decode_status        = dec_dw1[15:13];
        decode_byte_count    = dec_dw1[11:0];
        decode_requester_id  = dec_dw2[31:16];
        decode_tag           = dec_dw2[15:8];
        decode_lower_address = dec_dw2[6:0];

        decode_supported = (tlp_type == 5'b01010) &&
                           (((fmt == 3'b000) && (dec_dw0[9:0] == 10'd0)) ||
                            ((fmt == 3'b010) && (dec_dw0[9:0] == 10'd1))) &&
                           (dec_dw1[12] == 1'b0) &&
                           (dec_dw2[7] == 1'b0);
    end

endmodule