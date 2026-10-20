# Implementation Status

## Implemented in source

| Area | Current implementation | Evidence target |
|---|---|---|
| Endpoint packet interface | Abstract request/response handshake with operation, address, data, byte enables, Tag, Requester ID | RTL smoke and UVM monitor |
| Transaction handling | Single-DWORD Configuration/Memory Read and Write subset; one-entry response buffer | Directed RTL/UVM tests |
| Configuration | Vendor/Device ID, Revision/Class Code, Header Type, BAR0, capability pointer, basic PCIe capability header, modeled Command/Device Control fields | Configuration UVM tests |
| BAR0 | 256-byte BAR0 window, sizing probe, configurable aligned base within the abstract model | BAR sizing and memory tests |
| TLP codec and header checker | Encoder/decoder for 3-DW, one-DWORD Memory Read/Write request headers; separate structural checker for the same bounded subset | Header round-trip and `pcie_layer_blocks_tb` |
| Integrated TLP bridge | Connects bounded Memory Request headers/payload to Endpoint request/response logic; suppresses successful posted-write Completions and encodes Cpl/CplD for non-posted requests | `pcie_tlp_endpoint_tb` |
| Completion codec | Standalone 3-DW Completion/Completion-with-Data header codec for zero/one DWORD payload cases | Header round-trip smoke checks |
| CRC helper | Standalone reflected CRC-32 helper with known-answer vector | RTL smoke test |
| Data Link building blocks | Single-outstanding abstract transmit/replay controller with sequence number, saved packet, LCRC, ACK/NAK and replay timeout; standalone ACK/NAK DLLP control codec; receive sequence checker with duplicate suppression | `pcie_dll_replay_tb` and `pcie_layer_blocks_tb` |
| Tag tracker | First-free allocator and free validation for a parameterized Tag set | Add/maintain unit tests before integration |
| Flow-control manager | Credit counters for posted, non-posted, and Completion header/data classes | Add/maintain unit tests before integration |
| UVM | Active agent, item, sequencer, driver, monitor, scoreboard, coverage subscriber, directed and constrained-random sequences | UVM regression logs |
| Assertions | Endpoint response-stability and malformed-alignment properties; replay and credit assertions | Normal and checker-negative runs |

## Not implemented or not integrated

- The integrated TLP ingress/egress path supports only 3-DW, one-DWORD Memory Read/Write and Configuration Type 0 Read/Write requests. Configuration Type 1, 4-DW headers, multi-DWORD payloads, full malformed-packet rules, and full PCIe error-message generation remain unsupported. The internal register/memory core still uses an abstract request/response interface.
- The Data Link replay module is a bounded single-outstanding abstraction, not a complete PCIe Data Link implementation. DLLP encoding/decoding, protocol-exact ACK/NAK generation, full retry-buffer queueing, receive-side sequence checking/deduplication, full timers/state machine, per-VC flow-control initialization, and end-to-end integration remain incomplete.
- The credit manager and Tag tracker are standalone blocks and are not integrated with an Endpoint-originated requester/DMA path.
- Complete 4-DW and payload TLP support, all TLP formats/types, ECRC/digest, prefixes, all byte-count cases, split Completions, multiple outstanding requests, full ordering rules, Completion timeout, and complete malformed packet handling are not implemented.
- Full Configuration Space semantics, all BARs, MSI/MSI-X, Power Management, AER, and optional capabilities are not implemented.
- Physical Layer, LTSSM, Gen4 PHY, lane training/equalization, electrical signaling, PIPE compliance, and interoperability testing are out of scope for the current executable model.
- Complete DMA requester, host-memory model, interrupts, and integrated link-fault recovery remain incomplete.

## Verification status

The source includes a standalone self-checking RTL smoke test and UVM smoke/random tests. These have not been executed in this authoring environment because no Questa, Icarus Verilog, or Verilator executable is available here. No simulator run is represented as passing until a real Questa/other simulator log is available and reviewed. Coverage goals in `coverage_plan.md` are targets, not measured values. Record exact simulator version, commands, test names, seeds, results, and exclusions in `signoff_report.md`.

## Completion association tracker

`rtl/pcie_completion_tracker.sv` adds a standalone requester-side table for outstanding non-posted requests. It records Tag, Requester ID, expected byte count, and Lower Address, and checks incoming Completion metadata before releasing an entry. The directed test `tb/tests/pcie_completion_tracker_tb.sv` exercises valid matching, Requester ID mismatch, Byte Count mismatch, and successful recovery after an invalid Completion.

This block is not yet connected to a complete Endpoint requester/DMA path. It is a standalone building block and must not be described as end-to-end multiple-outstanding-request support.


## Additional Transaction/Data Link blocks

- `pcie_tlp_header_check.sv` reports structural errors for the currently supported 3-DW, one-DWORD Memory Read/Write header subset. It is not a full malformed-TLP checker and intentionally does not claim support for every legal PCIe header field combination.
- `pcie_dllp_codec.sv` provides a project-level packet representation for ACK/NAK control DLLPs, including a CRC-16/CCITT-FALSE integrity field. The byte ordering and integrity calculation have not been cross-validated against a PCIe conformance vector; treat it as a model codec, not a compliance implementation. Flow-control DLLPs are not encoded/decoded by this module.
- `pcie_dll_rx_seq.sv` accepts the expected sequence, suppresses a duplicate of the most recently accepted sequence, and requests NAK for bad-integrity or other out-of-order packets. It is a single-stream abstract checker, not the complete PCIe receiver/replay state machine.
- The replay controller now ignores replay-timeout input when no packet is awaiting acknowledgement and rejects zero-byte submissions. It remains a one-entry model.

## Additional transaction handling blocks

- `pcie_completion_assembler.sv` tracks remaining byte count and next lower address for a split Completion sequence per Tag. It accepts a successful fragment only when Tag, Requester ID, Byte Count, Lower Address, and payload byte count are consistent. Error Completions terminate the request. This is a bounded metadata model; payload storage and complete PCIe Completion legality checks are outside this module.
- `pcie_tlp_packet_buffer.sv` assembles a packet-level DWORD stream into a bounded single-packet buffer, preserving DWORD order and flagging malformed framing or capacity overflow. It is an abstract packet stream utility, not a PHY or full TLP parser.
- `tb/tests/pcie_advanced_tlp_tb.sv` exercises a two-fragment Completion and three-DWORD packet assembly. The test is registered as `advanced_tlp_smoke`.

These additions have not been compiled or simulated in the current environment. Do not treat them as verified until the directed tests and regression run in QuestaSim or another supported SystemVerilog simulator.

## Verification consolidation

A combined `pcie_coverage_regression_test` now runs the existing smoke, configuration, byte-enable, error, backpressure, boundary, mixed-operation, and constrained-random sequences in one simulation. This improves coverage accumulation for the supported packet-level endpoint model without adding new protocol features. Reset remains a separate test because it resets the DUT and reference model. Standalone RTL block tests remain separately tracked and do not contribute to the endpoint UVM covergroup.

The testbench and coverage model are implementation artifacts, not proof of simulation success. Populate the signoff report only from actual simulator logs and coverage databases.
