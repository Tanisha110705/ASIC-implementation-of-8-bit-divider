# rtl/

The Verilog RTL is not in the repository yet.

Files to add here:

| File | Top module | Used by |
| ---- | ---------- | ------- |
| `eight_bit_divider.v` (name as in the original project) | `eight_bit_divider` | Gate-level simulation and LEC ([docs/verification.md](../docs/verification.md)) |
| `divider1.v` | `divider_registers_8bit` | Genus synthesis study ([docs/rtl-to-gds-flow.md](../docs/rtl-to-gds-flow.md)) |

After adding them, complete the state table in [docs/fsm.md](../docs/fsm.md) and the datapath and algorithm sections of [docs/architecture.md](../docs/architecture.md) from the source.
