package pcie_pkg;

    typedef enum logic [2:0] {
    PCIE_OP_CFG_READ = 3'd0,
    PCIE_OP_CFG_WRITE = 3'd1,
    PCIE_OP_MEM_READ = 3'd2,
    PCIE_OP_MEM_WRITE = 3'd3,
    PCIE_OP_UNSUPPORTED = 3'd7
    } pcie_op_e;

    typedef enum logic [2:0] {
    PCIE_CPL_SUCCESS = 3'd0,
    PCIE_CPL_UR      = 3'd1,
    PCIE_CPL_CA      = 3'd2,
    PCIE_CPL_MALFORMED=3'd3
    } pcie_cpl_status_e;

    localparam logic [31:0] PCIE_BAR0_BASE = 32'h0000_1000;
    localparam int unsigned PCIE_BAR0_BYTES = 256;
    localparam int unsigned PCIE_CFG_DWORDS = 64;
    
endpackage
