# Architecture Notes

## Initial architecture

The first DUT is a PCIe Endpoint protocol block with a packet-level boundary to a simulated link partner. The packet-level interface is a project abstraction, not a claim that the interface is a standardized external PCIe interface.

```text
UVM link-partner model
        |
packet-level interface
        |
PCIe Endpoint DUT
  - TLP receive/decode
  - request dispatch
  - configuration space
  - BAR/register access
  - completion generation
  - later: Data Link Layer and flow control
```

Exact module boundaries and interface signals are intentionally TBD until the relevant specification sections have been studied.
