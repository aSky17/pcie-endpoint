// Decoder for the bounded 3-DW Configuration Type 0 Read/Write request subset.
// Supports one-DWORD accesses with First DW BE and zero Last DW BE.
module pcie_config_tlp_decoder (
    input  logic [95:0] header,
    output logic        supported,
    output logic        is_write,
    output logic [15:0] requester_id,
    output logic [7:0]  tag,
    output logic [3:0]  first_be,
    output logic [15:0] destination_id,
    output logic [11:0] register_offset
    );

    logic [31:0] dw0, dw1, dw2;
    logic [2:0] fmt;
    logic [4:0] tlp_type;
    logic read_type, write_type;

    always_comb begin
        dw0 = header[95:64];
        dw1 = header[63:32];
        dw2 = header[31:0];

        fmt = dw0[31:29];
        tlp_type = dw0[28:24];

        read_type = (fmt == 3'b000) && (tlp_type == 5'b00100);
        write_type = (fmt == 3'b010) && (tlp_type == 5'b00101);

        is_write = write_type;
        requester_id = dw1[31:16];

        tag = dw1[15:8];

        first_be = dw1[3:0];

        destination_id = dw2[31:16];
        register_offset = {dw2[11:2], 2'b00};

        supported = (read_type || write_type) && (dw0[9:0] == 10'd1) && (dw1[7:4] == 4'b0000) && (dw1[3:0] != 4'b0000) && (dw2[1:0] == 2'b00);
    end
endmodule
