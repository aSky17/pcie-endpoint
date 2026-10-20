// Packet-level DLLP control codec for ACK and NAK only.
// Exposes the 12-bit sequence value and a 16-bit integrity field separately;
// PHY serialization and protocol-exact CRC bit ordering are outside this model.
module pcie_dllp_codec (
    input  logic        encode_valid,
    input  logic        encode_nak,
    input  logic [11:0] encode_sequence,
    output logic        encode_supported,
    output logic [47:0] encoded_dllp,
    input  logic [47:0] decode_dllp,
    output logic        decode_valid,
    output logic        decode_nak,
    output logic [11:0] decode_sequence,
    output logic        decode_integrity_ok
);

    // Internal canonical representation: {type[15:0], sequence[15:0], crc[15:0]}.
    // The sequence is zero-extended in its upper nibble. CRC is a project-level
    // CRC-16/CCITT-FALSE helper over the first four bytes in MSB-first order.
    function automatic logic [15:0] crc16(input logic [31:0] d);
        logic [15:0] c;
        logic [7:0]  b;
        integer      i, j;

        begin
            c = 16'hFFFF;

            for (i = 3; i >= 0; i = i - 1) begin
                b = d[i*8 +: 8];
                c = c ^ {b, 8'b0};

                for (j = 0; j < 8; j = j + 1)
                    c = c[15] ? ((c << 1) ^ 16'h1021) : (c << 1);
            end

            crc16 = c;
        end
    endfunction

    logic [31:0] enc_body, dec_body;
    logic [15:0] dec_type, dec_seq, dec_crc;

    always_comb begin
        enc_body = {
            encode_nak ? 16'h0010 : 16'h0000,
            4'b0000,
            encode_sequence
        };

        encode_supported = encode_valid;
        encoded_dllp     = {enc_body, crc16(enc_body)};

        dec_body = decode_dllp[47:16];
        dec_type = dec_body[31:16];
        dec_seq  = dec_body[15:0];
        dec_crc  = decode_dllp[15:0];

        decode_valid = (dec_type == 16'h0000 || dec_type == 16'h0010) &&
                       dec_seq[15:12] == 4'b0000 &&
                       (dec_crc == crc16(dec_body));

        decode_nak         = (dec_type == 16'h0010);
        decode_sequence    = dec_seq[11:0];
        decode_integrity_ok = (dec_crc == crc16(dec_body));
    end

endmodule