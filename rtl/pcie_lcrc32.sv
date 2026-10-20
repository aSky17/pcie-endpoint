// Reflected CRC-32 helper for the bounded packet-level Data Link model.
// Bytes are consumed least-significant byte first. Framing/sequence insertion
// and PCIe PHY bit ordering are outside this helper's interface.
module pcie_lcrc32 (
    input  logic [127:0] packet_data,
    input  logic [4:0]   packet_bytes,
    output logic [31:0]  lcrc
    );
    
    function automatic logic [31:0] crc32_reflected(
        input logic [127:0] data,
        input logic [4:0] nbytes
        );
        logic [31:0] crc;
        logic [7:0] byte_value;
        integer i, b;
        begin
            crc = 32'hFFFF_FFFF;
            for (i = 0; i < 16; i = i + 1)
            begin
                if (i < nbytes)
                begin
                    byte_value = data[i*8 +: 8];
                    crc = crc ^ byte_value;
                    for (b = 0; b < 8; b = b + 1)
                    crc = crc[0] ? ((crc >> 1) ^ 32'hEDB8_8320) : (crc >> 1);
                end
            end
            crc32_reflected = ~crc;
        end
    endfunction

    always_comb begin
        if (packet_bytes <= 5'd16) lcrc = crc32_reflected(packet_data, packet_bytes);
        else lcrc = 32'h0000_0000;
    end
endmodule
