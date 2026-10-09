# Synthesis (Cadence Genus 21.14-s082_1)

## 1. Script

[`synthesis/scripts/genus_script.tcl`](../synthesis/scripts/genus_script.tcl), unchanged from the original upload:

| Step | Commands |
| ---- | -------- |
| Libraries | `init_lib_search_path ./lib/timing`; `read_libs` with 12 libraries: `{fast,slow}_{vdd1v0,vdd1v2}_basicCells{,_hvt,_lvt}.lib` |
| RTL | `init_hdl_search_path ./divider_rtl`; `read_hdl "divider.v"`; `elaborate eight_bit_divider` |
| Constraints | `read_sdc ./constraints.sdc` (copy one of the files in [`constraints/`](../constraints/) to this name) |
| Low power | `lp_insert_clock_gating true`, `lp_power_analysis_effort high`, `leakage_power_effort medium` |
| Optimisation | `syn_generic` → `syn_map` → `syn_opt`, all at medium effort |
| Reports | `report_timing`, `report_power`, `report_area`, `report_qor` → `./report_*.rpt` |
| Outputs | `write_hdl > divider_netlist.v`, `write_sdc > divider_sdc.sdc`, `write_sdf … > outputs/delays.sdf`, `write_do_lec -golden_design rtl -revised_design divider_netlist.v > rtl_to_final.tcl` |

The outputs feed the rest of the flow: `divider_netlist.v` goes to GLS, LEC and Innovus; `divider_sdc.sdc` to `mmmc.tcl` and Tempus; `outputs/delays.sdf` to the GLS testbench; `fv/eight_bit_divider/fv_map.v.gz` to LEC.

## 2. Results for `eight_bit_divider`

All values are read from the Genus report screenshots. Header for both runs: Genus 21.14-s082_1, operating conditions `PVT_1P1V_0C (balanced_tree)`, wireload mode `enclosed`, area mode `timing library`.

| Metric | 1000 ps run | 500 ps run |
| ------ | ----------: | ---------: |
| Report folder | [`eight_bit_divider_1000ps/`](../synthesis/reports/eight_bit_divider_1000ps/) | [`eight_bit_divider_500ps/`](../synthesis/reports/eight_bit_divider_500ps/) |
| SDC | [`divider_1000ps.sdc`](../constraints/divider_1000ps.sdc) | [`divider_500ps.sdc`](../constraints/divider_500ps.sdc) |
| QoR clock period | 1000.0 ps | 500.0 ps |
| Critical path (`report_timing`) | `a_reg[7]/CK` → `c_reg[4]/D` | `b_reg[1]/CK` → `c_reg[1]/D` |
| Data path / setup / uncertainty | 575 / 16 / 100 ps | 388 / 12 / 100 ps |
| Worst slack (`report_timing`) | **309 ps (MET)** | **0 ps (MET)** |
| QoR slack, CLOCK group | 308.6 ps | 0.3 ps |
| QoR slack, INPUTS group | 605.2 ps | 33.7 ps |
| QoR slack, OUTPUTS group | 578.2 ps | 78.2 ps |
| QoR slack, `cg_enable_group_clock` | 622.1 ps | 48.1 ps |
| TNS / violating paths | 0.0 / 0 | 0.0 / 0 |
| Leaf instances | 163 | 179 |
| Sequential / combinational / hierarchical | 51 / 112 / 4 | 51 / 128 / 4 |
| Cell area = total area (net area 0) | 511.974 | 524.286 |
| Clock-gating logic | 4 | 4 |
| Max fanout | 16 (`rc_gclk`) | 16 (`rc_gclk`) |
| Leakage power | 28.735 nW | 54.086 nW |
| Internal power | 196.869 µW (86.96 %) | 403.439 µW (87.01 %) |
| Switching power | 29.493 µW (13.03 %) | 60.164 µW (12.98 %) |
| **Total power** | **226.390 µW** | **463.658 µW** |
| Power by category: register / logic / clock | 67.80 % / 19.75 % / 12.45 % | 66.54 % / 21.30 % / 12.15 % |

Area is in the library's area unit (µm² for this library, as the lab report states). Power figures are Genus estimates from default switching activity (`/stim#0/frame#0`), not from simulation.

**Critical path.** In both runs the worst path is register-to-register through the 9-bit subtract-and-restore logic into `c_reg`: a chain of full adders (`ADDFX1`), then the restore mux (`AOI22XL` / `OAI2BB1X1*`). At 500 ps, Genus uses LVT cells on this path (`DFFRHQX1LVT`, `OAI2BB1X1LVT`, `ADDFX1LVT`) and reaches exactly 0 ps slack. At 1000 ps, mainly standard-Vt and HVT cells meet timing with 309 ps to spare. That makes 500 ps the tightest evidenced period (the folder "reports after slack 0").

**Minimum period.** Only two periods were run. 500 ps met with 0 ps slack; no shorter period was tried. 500 ps is therefore the lowest period **shown** to meet timing at synthesis (equivalent to 2 GHz). This is a pre-layout Genus estimate with ideal clocks, not a post-route or silicon frequency.

**1000 → 500 ps trade-off.** +16 cells, +2.4 % area, ×2.05 total power, ×1.88 leakage.

## 3. Constraints

| Parameter | `divider_1000ps.sdc` | `divider_500ps.sdc` |
| --------- | -------------------: | ------------------: |
| `PERIOD` | 1.0 ns | 0.5 ns |
| `INPUT_DELAY` (max) | 0.5 ns | 1.0 ns |
| `OUTPUT_DELAY` (max) | 0.5 ns | 0.25 ns |
| Clock latency (network / source), max | 0.25 / 0.25 ns | 0.25 / 0.25 ns |
| Clock latency, min | 0.05 / 0.05 ns | 0.05 / 0.05 ns |
| Uncertainty (setup and hold) | 0.1 ns | 0.1 ns |
| Clock transition | 0.05 ns | 0.05 ns |
| Min I/O delay | 0.1 ns | 0.1 ns |
| Max transition / fanout / capacitance | 0.2 / 20 / 80 | 0.2 / 20 / 80 |
| Clock excluded from I/O delays | `wb_clk_i` ⚠ | `clk` ✔ |

Known issues (files preserved unchanged):

1. `divider_1000ps.sdc` removes `[get_ports wb_clk_i]` from the input list. This design has no such port; the line is left over from a template. As a result, the input delay is also applied to `clk`.
2. In `divider_500ps.sdc`, the max input delay (1.0 ns) is larger than the clock period (0.5 ns). With these values an input-to-register path could not have positive slack, yet the 500 ps QoR report shows INPUTS slack +33.7 ps. The SDC in the run was probably different from the stored file. Re-run synthesis to confirm.
3. The file names in the original upload, "slack zero" and "slack not zero", were replaced by the clock period. The 500 ps file corresponds to the reports in "reports after slack 0" (0 ps slack). The 1000 ps file corresponds to "reports before slack 0" (309 ps slack).

## 4. Legacy study: `divider_registers_8bit`

The source repository contained Genus reports for a different module, `divider_registers_8bit` (from `divider1.v`; 38 flops; has a `load` port). It was run at 650 ps as baseline, clock-gated and PLE variants. Its RTL is not available, so it cannot be re-run or tied to `eight_bit_divider`. The reports and a transcription are kept in [`synthesis/reports/legacy_divider_registers_8bit/`](../synthesis/reports/legacy_divider_registers_8bit/README.md) for reference only.
