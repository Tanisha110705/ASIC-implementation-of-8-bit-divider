# Static Timing Analysis (Cadence Tempus 22.11)

Source: the author's ASIC Design Lab Task 5 ("Physical Verification and RC extraction"), run on 7 Nov 2025 in `asic/asiclab/pd_divider`. The design name in every Tempus capture is `eight_bit_divider`.

## 1. Inputs and script

[`timing-analysis/scripts/tempus_script.tcl`](../timing-analysis/scripts/tempus_script.tcl):

| Step | Commands |
| ---- | -------- |
| Libraries | same 12 `.lib` files as Genus; LEFs `gsclib045_tech.lef`, `gsclib045_{,hvt_,lvt_}macro.lef` |
| Design | `read_netlist ./divider_netlist.v`, `init_design`, `read_def ./divider_def.def` |
| Constraints / parasitics | `read_sdc ./divider_sdc.sdc`, `read_spef ./divider_spef.spef` |
| Analysis | `timing_analysis_type ocv`, `timing_analysis_cppr both`; SI delay calculation off (`delaycal_enable_si false`), SI reporting attributes set |
| Run | `update_timing -full`, `opt_signoff -hold` (hold target slack 0) |
| Reports | `report_timing`, `report_noise`, `report_annotated_parasitics`, `report_analysis_coverage`, `report_clocks`, `report_constraint -all_violators`, `report_analysis_summary`, … |

**Change made during consolidation:** the uploaded script still had template file names (`i2c_master_top_netlist.v`, `i2c_master_top.def`, `i2c_sdc.sdc`, `i2c.spef`). They were replaced by `divider_netlist.v`, `divider_def.def`, `divider_sdc.sdc` and `divider_spef.spef`, exactly as shown in the Task-5 report's capture of the script that was actually run. No other lines were changed. The final `source ./reports.tcl` line is kept; that file did not exist in the original run either (Tempus printed `IMPSE-112: couldn't read file "./reports.tcl"`).

## 2. RC extraction

[Capture](../timing-analysis/reports/rc_extraction.png) (Innovus `extract_rc`, IQuantus using RCgen models; ICECAPS models not available): 490 nets extracted, 5,018 resistors, 5,516 ground capacitors, 312 coupling capacitors.

**The SPEF stored in this repository is not the one used for this run.** [`divider.spef`](../timing-analysis/reports/divider.spef) is dated 26 Sep 2025 (Innovus 21.15-s110_1, `DESIGN_FLOW "PIN_CAP NONE"`) and contains 344 `*D_NET` entries and no ECO cells. The Task-5 report shows a `divider_spef.spef` dated 5 Nov 2025 with `DESIGN_FLOW "COUPLING C"`. The stored file is an earlier, pre-ECO extraction of `eight_bit_divider` and is kept as a sample of the parasitic data.

## 3. Results and ECO iterations

| # | Time (7 Nov) | Analysis | Total / passing / failing | WNS | TNS | Evidence |
| - | ------------ | -------- | ------------------------- | --: | --: | -------- |
| 0 | 16:00 | Setup | 115 / 115 / 0 | 0.000 ns (all slacks in histogram ≈ 0.31–0.55 ns) | 0.000 | [capture](../timing-analysis/reports/final_setup_hold_summary.png) (lower half) |
| 1 | 17:12 | Setup | 115 / 115 / 0 | 0.000 | 0.000 | [capture](../timing-analysis/reports/eco/00_setup_summary_0_failing.png) |
| 2 | 19:11 | Hold, initial | 115 / 82 / **33** | **−0.150 ns** | −1.425 ns | [capture](../timing-analysis/reports/eco/01_initial_hold_33_failing.png) |
| — | — | ECO 1: [`tempuszero.tcl`](../timing-analysis/reports/eco/02_tempuszero_eco_script.png), 25 `eco_add_repeater` commands visible (`BUFX20HVT`, `BUFX6LVT`, `BUFX4HVT`, …) → Innovus `source`, `place_eco`, `route_eco`, `write_db DBS/final.dat` | | | | |
| 3 | 19:38 | Hold, after ECO 1 | 114 / 100 / **14** | −0.013 ns | −0.074 ns | [capture](../timing-analysis/reports/eco/03_after_eco1_hold_14_failing.png) |
| — | — | ECO 2: [`tempuszero2.tcl`](../timing-analysis/reports/eco/04_tempuszero2_eco_script.png), 19 commands visible (`BUFX20HVT`, `BUFX6LVT`, `DLY1X1` on `q`/`p`/`done` nets) → same Innovus ECO steps | | | | |
| 4 | 19:38 | Hold, reported as "after ECO 2" | 114 / 114 / **0** | **−0.013 ns** | **−0.074 ns** | [capture](../timing-analysis/reports/final_setup_hold_summary.png) (upper half) |

The worst initial hold paths were `count_reg[0]/CK → count_reg[0]/D` (−0.150 ns), `y[2] → b_reg[2]/D` (−0.089 ns), and register-to-output paths such as `p_reg[0]/CK → p[0]` and `q_reg[7]/CK → q[7]` (−0.083 / −0.078 ns). The ECO scripts insert buffers and delay cells on exactly these output and input nets.

### Is hold closed?

**Not demonstrably.** Capture #4 is labelled "Hold Violations = 0" in the lab report, but:

- it shows WNS −0.013 ns and TNS −0.074 ns, identical to capture #3, which had 14 failing paths;
- it carries the same clock time (19:38) as capture #3;
- its histogram has the same shape and still has bars below 0 ns, now drawn in green.

A design with 0 failing paths cannot have a negative WNS under the same hold target, so the capture probably shows the same analysis with a different display or threshold setting. The lab report's written answer also gives "Worst hold violation: −0.013". Setup was re-captured only **before** the ECOs (16:00, 17:12), so post-ECO setup is not evidenced either. Closing this gap needs a fresh `report_timing -early` / `report_analysis_summary` text report on the final database.

## 4. Analysis coverage

[`report_analysis_coverage`](../timing-analysis/reports/report_analysis_coverage.png) (Tempus 22.11-s001_1, 19:21:50):

| Check type | Checks | Met | Violated | Untested |
| ---------- | -----: | --: | -------: | -------: |
| External delay (early / late) | 17 / 17 | 17 / 17 | 0 | 0 |
| Setup | 47 | 47 | 0 | 0 |
| Hold | 47 | 47 | 0 | 0 |
| Recovery / removal | 47 / 47 | 47 / 47 | 0 | 0 |
| Library clock-gating setup / hold | 8 / 8 | 4 / 4 | 0 | 4 / 4 |
| Pulse width | 149 | 102 | 0 | 47 (31 %) |

The same capture shows a clock-gating enable path (`count_reg[3]/CK → RC_CG_HIER_INST3/RC_CGIC_INST/E`) reported with slack −0.225 ns just above the coverage table. Its context (setup or hold, which view) is cut off, so it is listed here as an open item rather than interpreted.

## 5. Other observations from the lab report

- One clock (`clock`) is defined. The lab report says some paths were affected by constants.
- `report_noise` and the SI report attributes are set, but SI delay calculation is disabled (`delaycal_enable_si false`). Crosstalk was therefore not included in the delay numbers.
- Which SDC was used (1000 ps or 500 ps run) is not recorded. The ≥ 0.3 ns setup slacks and the 0.30 ns required times visible on output hold paths come from that unknown constraint set, so no clock frequency is claimed for the layout.
