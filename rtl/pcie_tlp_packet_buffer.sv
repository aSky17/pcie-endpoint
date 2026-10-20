// Single-packet DWORD assembler for a packet-level TLP stream abstraction.
// Stores the complete packet as DWORDs; it does not serialize PCIe symbols.
module pcie_tlp_packet_buffer #(
    parameter int unsigned MAX_DWORDS = 16,
    parameter int unsigned COUNT_WIDTH = $clog2(MAX_DWORDS+1)
    ) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic                         in_valid,
    output logic                         in_ready,
    input  logic                         in_sop,
    input  logic                         in_eop,
    input  logic [31:0]                  in_data,
    output logic                         packet_valid,
    input  logic                         packet_ready,
    output logic [MAX_DWORDS*32-1:0]     packet_data,
    output logic [COUNT_WIDTH-1:0]       packet_dwords,
    output logic                         packet_overflow,
    output logic                         framing_error
    );
    logic receiving_q;
    logic [31:0] work_mem [0:MAX_DWORDS-1];
    logic [COUNT_WIDTH-1:0] count_q;
    logic [MAX_DWORDS*32-1:0] packet_q;
    logic [COUNT_WIDTH-1:0] packet_count_q;
    logic packet_valid_q, overflow_q, framing_q;
    integer i;
    assign in_ready = rst_n && (!packet_valid_q || packet_ready);
    assign packet_valid = packet_valid_q;
    assign packet_data = packet_q;
    assign packet_dwords = packet_count_q;
    assign packet_overflow = overflow_q;
    assign framing_error = framing_q;
    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            receiving_q<=1'b0;
            count_q<='0;
            packet_q<='0;
            packet_count_q<='0;
            packet_valid_q<=1'b0;
            overflow_q<=1'b0;
            framing_q<=1'b0;
            for(i=0;i<MAX_DWORDS;i=i+1) work_mem[i]<='0;
        end
        else
        begin
            if (packet_valid_q && packet_ready) packet_valid_q<=1'b0;
            if (in_valid && in_ready)
            begin
                if (in_sop)
                begin
                    if (receiving_q)
                    begin
                        framing_q<=1'b1;
                        receiving_q<=1'b0;
                        count_q<='0;
                    end
                    else
                    begin
                        work_mem[0] <= in_data;
                        if (in_eop)
                        begin
                            packet_q <= '0;
                            packet_q[31:0] <= in_data;
                            packet_count_q <= {{(COUNT_WIDTH-1){1'b0}},1'b1};
                            packet_valid_q <= 1'b1;
                            receiving_q <= 1'b0;
                            count_q <= '0;
                        end
                        else
                        begin
                            receiving_q<=1'b1;
                            count_q<=1;
                        end
                    end
                end
                else if (!receiving_q)
                begin
                    framing_q<=1'b1;
                end
                else if (count_q >= MAX_DWORDS)
                begin
                    overflow_q<=1'b1;
                    receiving_q<=1'b0;
                    count_q<='0;
                end
                else
                begin
                    work_mem[count_q] <= in_data;
                    if (in_eop)
                    begin
                        packet_q <= '0;
                        for (i=0;i<MAX_DWORDS;i=i+1)
                        begin
                            if (i < count_q) packet_q[i*32 +: 32] <= work_mem[i];
                        end
                        packet_q[count_q*32 +: 32] <= in_data;
                        packet_count_q <= count_q + 1'b1;
                        packet_valid_q <= 1'b1;
                        receiving_q<=1'b0;
                        count_q<='0;
                    end
                    else count_q<=count_q+1'b1;
                end
            end
        end
    end
endmodule
