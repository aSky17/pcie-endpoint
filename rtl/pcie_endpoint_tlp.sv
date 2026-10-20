// Integrated bounded Endpoint top: 3-DW Memory Request TLP interface to the
// packet-level register/memory model. This is not a PHY or full PCIe link.
module pcie_endpoint_tlp #(
    parameter logic [15:0] VENDOR_ID     = 16'h1D0F,
    parameter logic [15:0] DEVICE_ID     = 16'hF001,
    parameter logic [15:0] COMPLETER_ID  = 16'h0000,
    parameter int unsigned BAR0_DWORDS   = 64
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        rx_valid,
    output logic        rx_ready,
    input  logic [95:0] rx_header,
    input  logic        rx_payload_valid,
    input  logic [31:0] rx_payload,
    output logic        tx_valid,
    input  logic        tx_ready,
    output logic [95:0] tx_header,
    output logic        tx_has_payload,
    output logic [31:0] tx_payload,
    output logic        error_event
);

    pcie_packet_if endpoint_bus(clk);

    assign endpoint_bus.rst_n = rst_n;

    pcie_endpoint #(
        .VENDOR_ID    (VENDOR_ID),
        .DEVICE_ID    (DEVICE_ID),
        .COMPLETER_ID (COMPLETER_ID),
        .BAR0_DWORDS  (BAR0_DWORDS)
    ) endpoint_core (
        .bus(endpoint_bus)
    );

    pcie_tlp_bridge #(
        .COMPLETER_ID(COMPLETER_ID)
    ) bridge (
        .clk              (clk),
        .rst_n            (rst_n),
        .rx_valid         (rx_valid),
        .rx_ready         (rx_ready),
        .rx_header        (rx_header),
        .rx_payload_valid (rx_payload_valid),
        .rx_payload       (rx_payload),
        .tx_valid         (tx_valid),
        .tx_ready         (tx_ready),
        .tx_header        (tx_header),
        .tx_has_payload   (tx_has_payload),
        .tx_payload       (tx_payload),
        .error_event      (error_event),
        .bus              (endpoint_bus)
    );

endmodule