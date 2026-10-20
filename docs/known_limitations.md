# Scope Boundaries and Known Limitations

## Specification baseline

The project uses PCI Express Base Specification Revision 4.0, Version 1.0 as its reference. Only features explicitly marked implemented and supported in the implementation status may be claimed as present.

## Current RTL and verification model

The internal Endpoint core is an abstract request/response model. The integrated `pcie_endpoint_tlp` wrapper additionally decodes a limited 96-bit 3-DW TLP header for one-DWORD Memory Read/Write and Configuration Type 0 Read/Write requests. This wrapper is not a serialized link or a general TLP parser. The design supports a small configuration-register model, a 256-byte BAR0 memory window, DWORD operations, byte-enable writes, a single-entry response buffer, basic response status, an active UVM agent, a monitor, scoreboard, functional coverage, and smoke/random sequences. See `implementation_status.md` for the exact list.

## Physical signaling and link training

The design does not implement analog/electrical PHY circuitry, SerDes, clock recovery, PLLs, impedance matching, electrical compliance, jitter analysis, lane margining, signal-integrity characterization, Gen4 equalization, or the complete LTSSM. A behavioral link model is not a real PCIe Gen4 physical link.

## Transaction Layer exclusions

The current RTL does not implement all legal Fmt/Type combinations, 4-DW TLP headers, multi-DWORD payloads, TLP digest/ECRC, prefixes, Configuration Type 1 requests, full Configuration Space semantics, complete capability lists, all BAR types, full Completion rules, multiple outstanding requester operations, split Completions, complete ordering attributes, completion timeout, DMA, MSI/MSI-X, AER, or power management.

## Data Link Layer exclusions

Standalone bounded helpers exist for reflected CRC-32, single-outstanding sequence/replay behavior, and abstract credit accounting. The integrated Endpoint does not implement protocol-complete DLLP encoding/decoding, sequence/LCRC processing on the TLP datapath, ACK/NAK DLLPs, a full replay queue/retransmission path, flow-control initialization over DLLPs, per-VC credit tracking, or complete Data Link state/recovery.

## Compliance claims

A passing regression establishes evidence for the tested implementation and model. It does not by itself establish full PCIe Base Specification compliance, interoperability with commercial Root Complexes, PHY compliance, or PCI-SIG certification.

## Status labels

- `planned`: specified but not implemented.
- `implemented`: source code exists; verification may be incomplete.
- `verified`: implementation exists and required tests/checkers passed with retained evidence.
- `partially_verified`: some evidence exists but requirements/coverage remain open.
- `not_supported`: explicitly outside the supported feature set.
- `waived`: requirement is excluded with written rationale and approval in project records.


## Additional implementation boundaries

- `pcie_tlp_codec.sv` only covers a 3-DW, single-DWORD Memory Read/Write header subset. It is a codec utility and is not wired into `pcie_endpoint.sv`.
- `pcie_lcrc32.sv` implements a reflected CRC-32 calculation over up to 16 bytes in the defined low-byte-first model. The helper's bit/byte ordering must be validated against the exact PCIe LCRC reference rules before claiming protocol compliance.
- `pcie_dll_replay.sv` models one outstanding packet and a simplified ACK/NAK/timeout replay loop. It does not encode DLLPs or implement a full PCIe retry buffer.
- `pcie_tag_tracker.sv` and `pcie_fc_credit_mgr.sv` are standalone modules; neither is connected to the packet-level Endpoint. The credit manager abstracts the credit update inputs rather than parsing Flow Control DLLPs.
- Simulation tools are not available in the authoring environment. All new SystemVerilog must be compiled and run with the target Questa installation before the code is treated as validated.


## Integrated TLP bridge boundary

The integrated top (`pcie_endpoint_tlp`) accepts 96-bit, 3-DW Memory Request and Configuration Type 0 request headers and a separate optional one-DWORD payload. It supports one-DWORD Memory Read/Write and Configuration Read/Write requests only. Successful posted writes do not emit Completions; successful reads emit a Completion-with-Data; unsupported non-posted requests emit an Unsupported Request Completion. Errors on posted writes are exposed as a local `error_event`, not a PCIe ERR_* Message TLP. Configuration Type 1 TLPs, 4-DW requests, multi-DWORD requests, complete byte-enable/length semantics, DLLP transport, and full Data Link/Physical Layer integration remain unsupported.

The Completion association tracker is currently standalone. The Endpoint has no integrated requester/DMA engine that allocates Tags, emits Memory Requests, receives Completions, assembles split payloads, and retires requests end-to-end. Do not infer that capability from the tracker module alone.


## Transaction/Data Link boundaries

The header checker only covers the implemented one-DWORD Memory Request subset. The ACK/NAK DLLP codec uses a project-level representation and CRC-16 helper; it has not been validated against PCIe 4.0 compliance vectors. It does not encode/decode flow-control DLLPs. The receive sequence checker models one sequence stream and only the expected/duplicate/out-of-order cases. These additions do not turn the existing replay block into a complete Data Link Layer: replay-buffer queues, DLLP timers/state, FC initialization/update exchange, receiver-side LCRC integration, and end-to-end DLL integration are still incomplete.

## Additional limits of the packet buffer and split Completion model

- The DWORD packet buffer holds one packet and exposes the whole packed packet at once; it does not provide a multi-beat output, backpressure inside a packet, or TLP header interpretation.
- The Completion assembler tracks metadata and byte progress only. It does not store/merge payload data, handle every PCIe byte-enable/alignment corner case, or implement full error recovery policy.
- New SystemVerilog additions require simulator compilation and directed regression before being considered verified.
