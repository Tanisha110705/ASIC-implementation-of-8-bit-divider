# constraints/

The SDC file (`constraints_file.sdc`) used for synthesis is not in the repository yet.

The Genus timing reports show these constraint values ([docs/results.md](../docs/results.md#1-synthesis-divider_registers_8bit-cadence-genus-2114-s082_1)):

| Constraint | Value |
| ---------- | ----- |
| Clock `clock` period | 650 ps |
| Clock source latency | 250 ps |
| Clock network latency | 250 ps (ideal) |
| Setup uncertainty | 100 ps |
| Input delay | 500 ps (`constraints_file.sdc`, line 56) |

Output delay, input transition, load and hold uncertainty are not visible in the evidence.
