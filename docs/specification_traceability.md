# Specification Traceability Matrix

The exact section/paragraph reference must be checked against the supplied PCI Express Base Specification Revision 4.0, Version 1.0 before a requirement is marked verified. The section numbers below identify likely specification areas; they are not substitutes for reading the normative text.

| Requirement ID | Requirement summary | Spec area to confirm | RTL owner | Verification evidence |
|---|---|---|---|---|
| TL-PKT-001 | Decode supported common TLP header fields | Ch. 2 §§2.2.1–2.2.6 | TLP decoder/package | Format/type/header tests; header coverage |
| TL-REQ-001 | Validate supported Memory and Configuration requests | Ch. 2 §§2.2.7, 2.3.1 | Validator/request handler | Request legality and negative tests |
| TL-CPL-001 | Generate correct Completion responses | Ch. 2 §§2.2.9, 2.3.2 | Completion generator | Completion scoreboard/checks |
| TL-BE-001 | Apply First/Last DW byte-enable rules | Ch. 2 §2.2.5 | Request handler/register file | Byte-enable tests/cross coverage |
| TL-ORD-001 | Enforce selected transaction ordering | Ch. 2 §2.4 | Ordering control | Ordering tests/assertions |
| TL-FC-001 | Coordinate transaction traffic with supported credits | Ch. 2 §2.6 and Ch. 3 §3.4 | Flow-control/TL gating | Credit tests and assertions |
| TL-ERR-001 | Handle unsupported/malformed received TLPs | Ch. 2 §2.3; applicable error sections | Validator/error handler | Negative tests/error coverage |
| TL-CFG-001 | Implement supported configuration header/capabilities | Ch. 7 and applicable Ch. 2 rules | Configuration space | Config tests and register model |
| DLL-STATE-001 | Track Data Link control state | Ch. 3 §§3.1–3.2 | DLL state controller | State transition tests/coverage |
| DLL-FC-001 | Implement supported FC initialization/update | Ch. 3 §§3.3–3.4 | Flow-control block | FC tests and credit coverage |
| DLL-DLLP-001 | Encode/decode supported DLLPs | Ch. 3 §3.5 | DLLP codec/control | DLLP format and error tests |
| DLL-SEQ-001 | Implement TLP sequence number rules | Ch. 3 §3.6 | DLL TX/RX | Sequence boundary/wrap tests |
| DLL-LCRC-001 | Generate/check TLP LCRC | Ch. 3 §3.6 | CRC/TX/RX | Reference vectors and corruption tests |
| DLL-RPLY-001 | Retain/replay unacknowledged TLPs | Ch. 3 §3.6 | Replay buffer/control | ACK/NAK/timeout/replay tests |
| PHY-LINK-001 | Model link status and fault/recovery events | Ch. 4 selected sections, project model contract | Link model | Link-up/down/recovery tests |
| CFG-RST-001 | Restore documented reset state | Relevant register and layer requirements | Config/endpoint/DLL | Reset tests/assertions |
| TB-SCB-001 | Detect missing, duplicate, mismatched packets | Project verification requirement | Scoreboard | Injected mismatch/negative checker test |
| TB-COV-001 | Cover applicable supported behaviors | Project verification requirement | Coverage collector | Coverage report and closure review |

## Traceability rules

- Add one row for every normative requirement selected for implementation.
- Include the exact specification section and a short paraphrase, not a copied long passage.
- Map each requirement to RTL module(s), test ID(s), assertion ID(s), and coverpoint/cross.
- Mark unsupported requirements as `not_supported` with a rationale and ensure no marketing/documentation claim implies support.
- A requirement is verified only when its implementation exists and the associated evidence has passed.
