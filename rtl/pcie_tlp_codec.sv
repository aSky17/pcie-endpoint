// Bounded PCIe 3-DW Memory Request header codec.
// This module encodes/decodes the wire header fields for one-DWORD Memory
// Read/Write requests. It is not a complete PCIe TLP codec.
module pcie_tlp_codec (
    input  logic        encode_valid,
    input  logic        encode_write,
    input  logic [9:0]  encode_length_dw,
    input  logic [15:0] encode_requester_id,
    input  logic [7:0]  encode_tag,
    input  logic [3:0]  encode_first_be,
    input  logic [3:0]  encode_last_be,
    input  logic [31:0] encode_address,
    output logic        encode_supported,
    output logic [95:0] encoded_header,

    input  logic [95:0] decode_header,
    output logic        decode_supported,
    output logic        decode_write,
    output logic [9:0]  decode_length_dw,
    output logic [15:0] decode_requester_id,
    output logic [7:0]  decode_tag,
    output logic [3:0]  decode_first_be,
    output logic [3:0]  decode_last_be,
    output logic [31:0] decode_address
);

    logic [31:0] enc_dw0, enc_dw1, enc_dw2;
    logic [31:0] dec_dw0, dec_dw1, dec_dw2;
    logic [2:0]  fmt;
    logic [4:0]  tlp_type;

    always_comb begin
        encoded_header = '0;

        encode_supported = encode_valid &&
                           (encode_length_dw == 10'd1) &&
                           (encode_address[1:0] == 2'b00) &&
                           (encode_first_be != 4'b0000) &&
                           (encode_last_be == 4'b0000);

        enc_dw0 = 32'b0;
        enc_dw1 = 32'b0;
        enc_dw2 = 32'b0;

        if (encode_supported) begin
            // Fmt=000b for 3-DW no-data Memory Read, Fmt=010b for 3-DW
            // Memory Write with data. Type=00000b identifies Memory Requests.
            enc_dw0[31:29] = encode_write ? 3'b010 : 3'b000;
            enc_dw0[28:24] = 5'b00000;
            enc_dw0[9:0]   = encode_length_dw;

            enc_dw1[31:16] = encode_requester_id;
            enc_dw1[15:8]  = encode_tag;
            enc_dw1[7:4]   = encode_last_be;
            enc_dw1[3:0]   = encode_first_be;

            enc_dw2[31:2] = encode_address[31:2];

            encoded_header = {enc_dw0, enc_dw1, enc_dw2};
        end
    end

    always_comb begin
        dec_dw0 = decode_header[95:64];
        dec_dw1 = decode_header[63:32];
        dec_dw2 = decode_header[31:0];

        fmt      = dec_dw0[31:29];
        tlp_type = dec_dw0[28:24];

        decode_write         = (fmt == 3'b010);
        decode_length_dw     = dec_dw0[9:0];
        decode_requester_id  = dec_dw1[31:16];
        decode_tag           = dec_dw1[15:8];
        decode_last_be       = dec_dw1[7:4];
        decode_first_be      = dec_dw1[3:0];
        decode_address       = {dec_dw2[31:2], 2'b00};

        decode_supported = (tlp_type == 5'b00000) &&
                           ((fmt == 3'b000) || (fmt == 3'b010)) &&
                           (dec_dw0[9:0] == 10'd1) &&
                           (dec_dw2[1:0] == 2'b00) &&
                           (dec_dw1[3:0] != 4'b0000) &&
                           (dec_dw1[7:4] == 4'b0000);
    end

endmodule