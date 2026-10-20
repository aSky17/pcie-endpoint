module pcie_tlp_header_check (
    input  logic [95:0] header,
    output logic        supported,
    output logic        is_write,
    output logic [3:0]  error_code
    );
    localparam logic [3:0] ERR_NONE     = 4'd0;
    localparam logic [3:0] ERR_FMT_TYPE = 4'd1;
    localparam logic [3:0] ERR_LENGTH   = 4'd2;
    localparam logic [3:0] ERR_ADDRESS  = 4'd3;
    localparam logic [3:0] ERR_FIRST_BE = 4'd4;
    localparam logic [3:0] ERR_LAST_BE  = 4'd5;
    localparam logic [3:0] ERR_RESERVED = 4'd6;
    logic [31:0] dw0, dw1, dw2;
    logic [2:0]  fmt;
    logic [4:0]  typ;
    logic [3:0]  fbe, lbe;
    always_comb
    begin
        dw0 = header[95:64];
        dw1 = header[63:32];
        dw2 = header[31:0];
        fmt = dw0[31:29];
        typ = dw0[28:24];
        fbe = dw1[3:0];
        lbe = dw1[7:4];
        is_write  = (fmt == 3'b010);
        supported = 1'b0;
        error_code = ERR_NONE;
        if (typ != 5'b00000 ||
        !((fmt == 3'b000) || (fmt == 3'b010)))
        begin
            error_code = ERR_FMT_TYPE;
        end
        else if (dw0[9:0] != 10'd1)
        begin
            error_code = ERR_LENGTH;
        end
        else if (dw2[1:0] != 2'b00)
        begin
            error_code = ERR_ADDRESS;
        end
        else if (fbe == 4'b0000)
        begin
            error_code = ERR_FIRST_BE;
        end
        else if (lbe != 4'b0000)
        begin
            error_code = ERR_LAST_BE;
        end
        else if (dw0[23:10] != 14'b0)
        begin
            error_code = ERR_RESERVED;
        end
        else
        begin
            supported = 1'b1;
            error_code = ERR_NONE;
        end
    end
endmodule
