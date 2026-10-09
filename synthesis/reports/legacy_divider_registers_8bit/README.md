# Legacy synthesis study: `divider_registers_8bit` (not the main design)

> **These reports belong to a different RTL module, not to `eight_bit_divider`.** `divider_registers_8bit` was read from `divider1.v`, has a `load` input and synthesises to 38 flip-flops. Its RTL is not available in either source repository. The reports are kept because they show three Genus techniques (baseline, clock-gating insertion and physical-aware PLE) at a 650 ps clock. **No number in this folder applies to `eight_bit_divider`.**

Origin: `RTL-of-8-bit-Divider/reports/synthesis/`, which matches the author's ASIC Design Lab Task 2 report ("Logic Synthesis and Optimisation", Aug 2025). Tool: Genus 21.14-s082_1, `PVT_1P1V_0C`, clock `clock` = 650 ps, 250 ps source + 250 ps ideal network latency, 100 ps setup uncertainty, 500 ps input delay.

| Run | Folder | What changed |
| --- | ------ | ------------ |
| Baseline | [`01_baseline/`](01_baseline/) | `syn_generic` → `syn_map` → `syn_opt` (medium), no clock gating |
| Clock gating | [`02_clock_gating/`](02_clock_gating/) | Clock-gating insertion (1 ICG, 8 of 38 flops gated) |
| PLE | [`03_ple/`](03_ple/) | Physical layout estimation (`Interconnect mode: spatial`, `Area mode: physical library`) |

Each folder holds `report_timing.png`, `report_area.png`, `report_power.png`, `report_qor.png` and `report_clock_gating.png`.

## Results (transcribed from the screenshots)

| Metric | Baseline | + Clock gating | PLE |
| ------ | -------: | -------------: | --: |
| Leaf cells (seq / comb) | 99 (38 / 61) | 91 (39 / 52) | 106 (39 / 67) |
| Cell area | 300.960 | 305.406 | 259.493 |
| Net area | 0.000 | 0.000 | 76.205 |
| **Total area** | **300.960** | **305.406** | **335.698** |
| Leakage power (µW) | 0.1407 | 0.1289 | 0.1174 |
| Internal power (µW) | 195.268 | 195.111 | 196.348 |
| Switching power (µW) | 32.934 | 31.879 | 43.644 |
| **Total power (µW)** | **228.343** | **227.119** | **240.109** |
| Worst setup slack @ 650 ps | 0 ps | 1 ps | 3 ps |
| Worst path | `load` → `count_reg[3]/D` | `rst` → `A_reg[10]/D` | `load` → `Q_reg[0]/D` |
| QoR slack, OUTPUTS group | 10.6 ps | 9.5 ps | 8.7 ps |
| Gated flops | 0 / 38 | 8 / 38 | 8 / 38 |

Worst baseline path budget: `650 = 500 (input delay) + 37 (logic) + 13 (setup) + 100 (uncertainty)`. The 650 ps limit is set by the SDC I/O budget, not by internal logic depth. The lab report calls 650 ps "Tmax" (the period at which slack reaches 0).

Note: the lab report labels the per-cost-group QoR slacks (0 / 10.6 / 9.5 / 3.2 / 8.7 ps) as "Performance (input/output/clock delay)". In Genus they are critical-path **slacks** per cost group.
