interface pcie_packet_if (
    input logic clk
);
    import pcie_pkg::*;

    logic        rst_n;
    logic        req_valid, req_ready;
    pcie_op_e    req_op;
    logic [31:0] req_addr, req_wdata;
    logic [3:0]  req_be;
    logic [7:0]  req_tag;
    logic [15:0] req_requester_id;
    logic        rsp_valid, rsp_ready;
    pcie_op_e    rsp_op;
    logic [31:0] rsp_rdata;
    logic [7:0]  rsp_tag;
    logic [15:0] rsp_requester_id, rsp_completer_id;
    pcie_cpl_status_e rsp_status;
    logic [3:0]  rsp_byte_count;

    modport dut (
        input  clk, rst_n, req_valid, req_op, req_addr, req_wdata, req_be,
               req_tag, req_requester_id, rsp_ready,
        output req_ready, rsp_valid, rsp_op, rsp_rdata, rsp_tag,
               rsp_requester_id, rsp_completer_id, rsp_status, rsp_byte_count
    );

    modport bridge (
        input  clk, rst_n, req_ready, rsp_valid, rsp_op, rsp_rdata, rsp_tag,
               rsp_requester_id, rsp_completer_id, rsp_status, rsp_byte_count,
        output req_valid, req_op, req_addr, req_wdata, req_be, req_tag,
               req_requester_id, rsp_ready
    );

    modport tb (
        input  clk, req_ready, rsp_valid, rsp_op, rsp_rdata, rsp_tag,
               rsp_requester_id, rsp_completer_id, rsp_status, rsp_byte_count,
        output rst_n, req_valid, req_op, req_addr, req_wdata, req_be,
               req_tag, req_requester_id, rsp_ready
    );

endinterface
