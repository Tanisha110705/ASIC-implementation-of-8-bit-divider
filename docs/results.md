# Results and Evidence Index

Every number quoted in this repository is listed here with its source. If a value is not here, the repository has no evidence for it. Screenshots are unedited tool output.

## 1. RTL and functional verification — `eight_bit_divider`

| Quantity | Value | Kind | Source |
| -------- | ----- | ---- | ------ |
| Operand / result widths | 8-bit `x`, `y` → 8-bit `q`, `p` | RTL | [`rtl/divider.v`](../rtl/divider.v) |
| FSM states | `IDLE`=00, `DIVIDE`=01, `DONE`=10 | RTL | `rtl/divider.v` |
| Iterations per division | 8 | RTL (`count < 8`) | `rtl/divider.v` |
| Latency, `start` sampled → `done` | 9 rising edges | RTL sim, GLS | [`tb_divider_exhaustive.v`](../verification/testbench/tb_divider_exhaustive.v), [GLS waveform](../verification/gls/reports/02_waveforms.png) |
| Flip-flops | 47 | Yosys; Conformal | `make lint`; [LEC](../verification/lec/reports/07_lec_output_1.png) |
| Directed tests | 6/6 correct | ModelSim, Xcelium, Icarus | [transcript](../verification/simulation/rtl/modelsim_transcript.png) |
| Exhaustive test | 65,536 pairs + 2 protocol tests, 0 errors | Icarus 12 (this consolidation) | `make -C verification exhaustive` |
| Coverage | overall 82.9 %, block 92.86 %, toggle 69.31 %, FSM 87.5 % | IMC | [capture](../verification/simulation/rtl/imc_coverage.png) |

## 2. Synthesis — `eight_bit_divider`, Genus 21.14-s082_1

| Quantity | 1000 ps | 500 ps | Source |
| -------- | ------: | -----: | ------ |
| Worst setup slack | 309 ps | 0 ps | `report_timing.png` in [1000 ps](../synthesis/reports/eight_bit_divider_1000ps/report_timing.png) / [500 ps](../synthesis/reports/eight_bit_divider_500ps/report_timing.png) |
| Leaf cells (seq / comb) | 163 (51 / 112) | 179 (51 / 128) | `report_qor_1.png` |
| Area | 511.974 | 524.286 | `report_area.png` |
| Total power | 226.390 µW | 463.658 µW | `report_power.png` |
| Leakage | 28.735 nW | 54.086 nW | `report_qor_2.png` |
| Clock-gating logic | 4 | 4 | `report_qor_2.png` |

## 3. Gate-level simulation and LEC — `eight_bit_divider`

| Quantity | Value | Source |
| -------- | ----- | ------ |
| GLS results | 6/6 correct, SDF MAXIMUM | [waveform](../verification/gls/reports/02_waveforms.png) |
| Clock → `done` | 47 ps | [capture](../verification/gls/reports/04_done_delay.png) |
| Clock → `q`/`p` | 125 ps | [capture](../verification/gls/reports/05_output_delay.png) |
| LEC compare points | 64 EQ (17 PO + 47 DFF), 0 NEQ / abort / uncompared | [capture](../verification/lec/reports/08_lec_output_2.png) |
| LEC verdict | PASS (fv_map vs final netlist) | same |

## 4. Physical design — Innovus 21.15 (Task 4 run, `pd_final`)

| Stage | Setup WNS / #viol | Hold WNS / #viol | Density | Source |
| ----- | ----------------- | ---------------- | ------: | ------ |
| Placement (pre-CTS) | −0.206 ns / 9 | −0.241 ns / 115 | 47.33 % | [`reports/place/`](../physical-design/reports/place/) |
| Post-CTS before opt | +0.007 ns / 0 | −0.101 ns / 113 | 48.44 % | [`reports/cts/`](../physical-design/reports/cts/) |
| Post-CTS after opt | −0.000 ns / 1 | −0.009 ns / 3 | 61.77 % | `reports/cts/` |
| Post-route before opt | −0.039 ns / 8 | −0.030 ns / 26 | 61.77 % | [`reports/route/`](../physical-design/reports/route/) |
| Post-route after opt | −0.044 ns / 9 | −0.030 ns / 25 | 62.33 % | `reports/route/` |

| Check | Value | Source |
| ----- | ----- | ------ |
| Placed instances | 304 (0 unplaced) | [check_place](../physical-design/reports/place/check_place.png) |
| `check_drc` / `check_connectivity` | 0 / 0 | [drc](../physical-design/reports/route/check_drc.png), [connectivity](../physical-design/reports/route/check_connectivity.png) |
| Die boundary | 59.6 × 55.67 µm | check_connectivity |

## 5. Final database and STA — Innovus + Tempus 22.11 (Task 5 run, `pd_divider`)

| Quantity | Value | Source |
| -------- | ----- | ------ |
| Die boundary | 57.6 × 57.38 µm | [check_connectivity](../physical-design/reports/final_db/check_connectivity.png) |
| `check_drc` / `check_connectivity` | 0 / 0 | [`final_db/`](../physical-design/reports/final_db/) |
| Extraction | 490 nets, 5,018 R, 5,516 C, 312 coupling C | [rc_extraction](../timing-analysis/reports/rc_extraction.png) |
| Setup (before ECO) | 115 paths, 0 failing | [capture](../timing-analysis/reports/eco/00_setup_summary_0_failing.png) |
| Hold, initial | 33 failing, WNS −0.150 ns, TNS −1.425 ns | [capture](../timing-analysis/reports/eco/01_initial_hold_33_failing.png) |
| Hold, after ECO 1 | 14 failing, WNS −0.013 ns, TNS −0.074 ns | [capture](../timing-analysis/reports/eco/03_after_eco1_hold_14_failing.png) |
| Hold, "after ECO 2" | 0 failing shown, but WNS −0.013 ns, TNS −0.074 ns | [capture](../timing-analysis/reports/final_setup_hold_summary.png) |
| Analysis coverage | setup 47/47, hold 47/47 met; 4 CG checks and 47 pulse-width checks untested | [capture](../timing-analysis/reports/report_analysis_coverage.png) |

## 6. Not available — not claimed

| Item | Status |
| ---- | ------ |
| GDSII / `write_stream` | No evidence |
| Sign-off DRC / LVS / antenna / fill | No evidence (only Innovus `check_drc` / `check_connectivity`) |
| Post-route power, IR drop, EM | No evidence |
| Post-layout maximum frequency | Not claimed; the SDC used in Innovus/Tempus is not recorded |
| Hold closure with non-negative WNS | Not demonstrated (see [timing-analysis.md](timing-analysis.md#is-hold-closed)) |
| Post-ECO setup analysis | Not captured |
| RTL-to-netlist equivalence | Not run (dofile generated by Genus only) |
| ECO scripts as files, Genus netlist/SDF, DEF, final SPEF, text reports | Not preserved (routing script recovered from the Task-4 report capture) |
| Utilisation and area after P&R in µm² | Only densities and die boundaries are captured |

## 7. Legacy study — `divider_registers_8bit` (different RTL)

Separate design; see [`synthesis/reports/legacy_divider_registers_8bit/`](../synthesis/reports/legacy_divider_registers_8bit/README.md). Summary: 650 ps met in all three runs (slack 0 / 1 / 3 ps); area 300.960 / 305.406 / 335.698; total power 228.343 / 227.119 / 240.109 µW (baseline / clock-gated / PLE).
