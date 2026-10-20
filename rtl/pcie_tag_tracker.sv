// Synthesizable Tag allocator for an abstract Endpoint requester.
// Allocation is first-free; callers must only free Tags previously allocated.
module pcie_tag_tracker #(
    parameter int unsigned TAG_COUNT = 32,
    parameter int unsigned TAG_WIDTH = $clog2(TAG_COUNT)
) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic                         alloc_valid,
    output logic                         alloc_ready,
    output logic [TAG_WIDTH-1:0]         alloc_tag,
    input  logic                         free_valid,
    input  logic [TAG_WIDTH-1:0]         free_tag,
    output logic                         free_error,
    output logic [$clog2(TAG_COUNT+1)-1:0] active_count
);

    logic [TAG_COUNT-1:0] allocated;
    logic                 found;
    integer               i;

    always_comb begin
        alloc_ready = 1'b0;
        alloc_tag   = '0;
        found       = 1'b0;

        for (int k = 0; k < TAG_COUNT; k++) begin
            if (!allocated[k] && !found) begin
                alloc_ready = 1'b1;
                alloc_tag   = TAG_WIDTH'(k);
                found       = 1'b1;
            end
        end

        active_count = '0;

        for (int k = 0; k < TAG_COUNT; k++)
            active_count = active_count + allocated[k];

        free_error = 1'b0;

        if (free_valid) begin
            if (free_tag >= TAG_COUNT)
                free_error = 1'b1;
            else if (!allocated[free_tag])
                free_error = 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            allocated <= '0;
        else begin
            if (free_valid && !free_error)
                allocated[free_tag] <= 1'b0;

            if (alloc_valid && alloc_ready)
                allocated[alloc_tag] <= 1'b1;
        end
    end

`ifndef SYNTHESIS
    property p_no_duplicate_allocation;
        @(posedge clk) disable iff (!rst_n)
        alloc_valid && alloc_ready |-> !allocated[alloc_tag];
    endproperty

    assert property (p_no_duplicate_allocation)
    else $error("Tag allocator allocated an active Tag");
`endif

endmodule