# Reproduction Guide

## 1. Open-source checks (anyone)

Tested on Ubuntu 24.04 with Icarus Verilog 12.0 and Yosys 0.33.

```sh
sudo apt-get install iverilog yosys
make -C verification sim          # directed TB: prints the 6 original results
make -C verification exhaustive   # self-checking: "Checked 65538 operations / TEST PASSED", ~3 s
make -C verification lint         # Yosys: 0 problems, 47 DFFs
make -C verification clean
```

The testbenches have no `` `timescale `` and run unchanged in ModelSim or Xcelium:
`xrun -timescale 1ns/10ps rtl/divider.v verification/testbench/tb_divider_exhaustive.v`.

## 2. Cadence flow (licensed tools and PDK required)

### 2.1 Prerequisites (not included in this repository)

| Item | Used by | Notes |
| ---- | ------- | ----- |
| Genus 21.14, Xcelium + SimVision, Conformal LEC, Innovus 21.15, Tempus 22.11 | all | Versions as shown in the reports; other versions may work |
| `lib/timing/{fast,slow}_{vdd1v0,vdd1v2}_basicCells{,_hvt,_lvt}.lib` | Genus, Innovus, Tempus | Cadence 45 nm GPDK standard-cell libraries |
| `lib/verilog/slow_vdd1v0_basicCells{,_lvt,_hvt}.v` | Conformal, Xcelium GLS | cell simulation models |
| `lib/lef/gsclib045_tech.lef`, `gsclib045_{,hvt_,lvt_}macro.lef` | Innovus, Tempus | technology and cell LEFs |
| `lib/qrc/gpdk045.tch`, `lib/captable/cln28hpl_1p10m+alrdl_5x2yu2yz_typical.capTbl` | Innovus `mmmc.tcl` | RC models (file names as in the script) |

These files are licensed PDK content and must not be committed. The `.gitignore` excludes tool run directories and logs; keep `lib/` outside the repository or add it to `.gitignore`.

### 2.2 Working directory

All scripts use paths relative to one working directory (originally `~/asiclab/divider`). Set it up like this:

```text
work/
├── lib/                   ← PDK files from 2.1
├── divider_rtl/divider.v  ← copy of rtl/divider.v   (Genus init_hdl_search_path)
├── constraints.sdc        ← copy of constraints/divider_1000ps.sdc or divider_500ps.sdc
├── outputs/               ← create empty; Genus writes delays.sdf here
└── DBS/                   ← create empty; Innovus write_db target
```

### 2.3 Execution order

| # | Step | Command (from `work/`) | Consumes | Produces |
| - | ---- | ---------------------- | -------- | -------- |
| 1 | Synthesis | `genus -f <repo>/synthesis/scripts/genus_script.tcl` | `divider_rtl/divider.v`, `constraints.sdc`, `lib/timing` | `divider_netlist.v`, `divider_sdc.sdc`, `outputs/delays.sdf`, `fv/eight_bit_divider/fv_map.v.gz`, `rtl_to_final.tcl`, `report_*.rpt` |
| 2 | Gate-level sim | `sh <repo>/verification/gls/run_gls` | `filelist_gls` (create it: `divider_netlist.v`, `lib/verilog/slow_vdd1v0_basicCells*.v`, `<repo>/verification/gls/tb_eight_bit_divider_gls.v`), `outputs/delays.sdf` | SimVision waveforms, `sdf.log` |
| 3 | Equivalence | `lec -xl -nogui -dofile <repo>/verification/lec/divider_lec.do` | `fv/…/fv_map.v.gz`, `divider_netlist.v`, `lib/verilog` | LEC report (expect 64 EQ, PASS) |
| 3b | RTL-to-gates LEC (not run before) | `lec -xl -nogui -dofile rtl_to_final.tcl` | Genus-generated dofile | — |
| 4 | Innovus init | in `innovus`: `read_mmmc <repo>/physical-design/scripts/mmmc.tcl`; `read_physical -lef {…LEFs…}`; `read_netlist divider_netlist.v`; `init_design` | step 1 outputs | — |
| 5 | Floorplan | `source <repo>/physical-design/scripts/floorplan_CUI.tcl` | | `DBS/init.dat` |
| 6 | Placement | `source <repo>/physical-design/scripts/place_CUI.tcl` | | `DBS/place.dat` |
| 7 | CTS | `source <repo>/physical-design/scripts/cts_CUI.tcl` | | `DBS/cts.dat`, `DBS/postcts_hold.dat` |
| 8 | Routing | `source <repo>/physical-design/scripts/route_CUI.tcl` | | `DBS/route.dat`, `DBS/postroute.dat` |
| 9 | Export for STA | `extract_rc`; `write_parasitics -spef_file divider_spef.spef -rc_corner rccorners`; `write_netlist divider_netlist.v`; `write_def divider_def.def` | | inputs for Tempus |
| 10 | STA | `tempus -files <repo>/timing-analysis/scripts/tempus_script.tcl` | step 9 + `divider_sdc.sdc` | timing reports, `top.mtarpt` |
| 11 | ECO | in Tempus: `write_eco -format innovus tempuszero.tcl`; in Innovus: `read_db DBS/postroute.dat`, `source tempuszero.tcl`, `place_eco`, `route_eco`, `write_db DBS/final.dat`; repeat 9–11 | | `DBS/final.dat` |
| 12 | GDSII (never run) | `write_stream divider.gds -map_file <gpdk045 streamOut.map> …` | | — |

Step 4: the original `init_design` commands were not preserved. The commands listed are the standard Innovus 21 equivalents.
Steps 9 and 12 are documented from the lab report's description. They are not taken from preserved scripts.

### 2.4 Expected outcomes

Use [results.md](results.md) as the reference. Small differences are normal between tool versions, and between the two SDC files.

## Provenance file map

| Current path | Original location |
| ------------ | ----------------- |
| `rtl/divider.v` | `ASIC-implementation…/RTL & Verification /divider_8bit.v` (byte-identical) |
| `verification/testbench/tb_divider_8bit.v` | `ASIC-implementation…/RTL & Verification /tb_divider_8bit.v` (byte-identical) |
| `verification/testbench/tb_divider_exhaustive.v`, `verification/Makefile` | new in this consolidation |
| `verification/simulation/rtl/modelsim_transcript.png`, `modelsim_waveform.png`, `xcelium_waveform.png`, `imc_coverage.png` | `RTL & Verification /output/` (`output.png`, `waveform(modelsim).png`, `waveform(xcelium).png`, `Screenshot 2026-09-04 103831.png`) |
| `verification/gls/reports/01–05*.png`, `verification/lec/reports/06–08*.png` | `ASIC-implementation…/gls-lec/` |
| `verification/gls/tb_eight_bit_divider_gls.v`, `verification/gls/run_gls`, `verification/lec/divider_lec.do` | `RTL-of-8-bit-Divider/tb/`, `scripts/gls/`, `scripts/lec/` |
| `constraints/divider_1000ps.sdc`, `divider_500ps.sdc` | `Synthesis /constraints.sdc (slack not zero)`, `(slack zero)` |
| `synthesis/scripts/genus_script.tcl` | `Synthesis /genus_script.tcl` |
| `synthesis/reports/eight_bit_divider_1000ps/` | `Synthesis /reports before slack 0/` (screenshots renamed by content) |
| `synthesis/reports/eight_bit_divider_500ps/` | `Synthesis /reports after slack 0/` |
| `synthesis/reports/legacy_divider_registers_8bit/` | `RTL-of-8-bit-Divider/reports/synthesis/` |
| `physical-design/scripts/*` | `physical design/mmmc.tcl`, `floorplan/`, `place/`, `cts/` scripts (`cts_CUI.tcl`: SPEF name corrected to match the Task-4 capture); `route_CUI.tcl` transcribed from the Task-4 report, page 9 |
| `physical-design/reports/*`, `physical-design/layout/01–03*.png` | `physical design/{floorplan,place,cts,route}/*.png` |
| `physical-design/reports/final_db/*`, `physical-design/layout/04_post_route_final_db.png` | `physical verification/{drc_violations,check_connectivity,post_route_design}.png` |
| `timing-analysis/scripts/tempus_script.tcl` | `physical verification/tempus_script.tcl` (4 file names corrected, see [timing-analysis.md](timing-analysis.md#1-inputs-and-script)) |
| `timing-analysis/reports/*` | `physical verification/` (`divider.spef`, `rc_extraction.png`, `report_analysis_coverage.png`, `GUI.png` → `tempus_schematic.png`, `zero setup and hold violations.png` → `final_setup_hold_summary.png`) |
| `timing-analysis/reports/eco/*.png` | extracted from the author's Task-5 lab report PDF (pages 6–9) |
| `assets/cycle-operation.svg`, `.gitignore` | `RTL-of-8-bit-Divider/assets/`, `.gitignore` |
| `assets/divider-architecture.svg`, `assets/rtl-to-gds-flow.svg`, `README.md`, `docs/*` | new in this consolidation |

Everything else from `RTL-of-8-bit-Divider` (its README, docs, placeholder READMEs, old SVGs, cropped GLS/LEC images and the duplicate `fsm-divider-rtl/` folder) is preserved unchanged in [`docs/archive/rtl-of-8-bit-divider/`](archive/README.md). The superseded parts are explained there.

| Added path | Source |
| ---------- | ------ |
| `docs/lab-reports/task2_logic_synthesis.docx`, `task3_gls_lec.docx`, `task4_physical_design.pdf`, `task5_sta_rc_extraction.pdf` | the author's uploaded lab submissions (Tasks 2, 3, 4, 5), committed unchanged |
| `docs/archive/original-destination-README.md` | this repository's README before consolidation |
| `physical-design/reports/route/route_CUI_script_capture.png`, `physical-design/reports/cts/cts_CUI_script_capture.png` | extracted from the Task-4 report (pages 9 and 5) |

Replaced: `physical design/route/route_CUI.tcl` was a byte-identical copy of `cts_CUI.tcl`. It was replaced by `physical-design/scripts/route_CUI.tcl`, transcribed from the Task-4 report capture. Removed: two empty `git.keep` files. The old versions remain in git history.
