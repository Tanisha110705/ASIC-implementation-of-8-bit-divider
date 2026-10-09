# Verification

| Level | What | Tool | Status |
| ----- | ---- | ---- | ------ |
| RTL, directed | 6 operand pairs, printed results | ModelSim 2021.1 (Intel FPGA Starter), Xcelium/SimVision, Icarus 12 | Pass (manual check of printed values; re-run here) |
| RTL, exhaustive | All 65,536 pairs, latency, hold, protocol, reset | Icarus 12 | **Pass** (self-checking; added in this consolidation) |
| RTL coverage | Code + FSM coverage of the directed test | Cadence IMC | 82.9 % overall |
| Gate level | Genus netlist + SDF, 6 directed pairs | Xcelium, SimVision | Pass (waveform inspection) |
| Equivalence | Genus `fv_map` vs final netlist | Conformal LEC | PASS, 64/64 |

## 1. Directed RTL testbench

[`verification/testbench/tb_divider_8bit.v`](../verification/testbench/tb_divider_8bit.v) (original, unchanged). It uses a 10-unit clock and asserts reset for 50 units. The `run_division` task drives `x`/`y` on a falling edge, pulses `start` for one cycle, waits for `done`, then prints the result on the next rising edge.

| x | y | Expected q / p | ModelSim | Icarus (this consolidation) |
| -: | -: | -------------- | -------- | --------------------------- |
| 13 | 3 | 4 / 1 | 4 / 1 | 4 / 1 |
| 100 | 7 | 14 / 2 | 14 / 2 | 14 / 2 |
| 50 | 5 | 10 / 0 | 10 / 0 | 10 / 0 |
| 200 | 15 | 13 / 5 | 13 / 5 | 13 / 5 |
| 77 | 1 | 77 / 0 | 77 / 0 | 77 / 0 |
| 55 | 0 | 0 / 55 (defined) | 0 / 55 | 0 / 55 |

Evidence: [ModelSim transcript](../verification/simulation/rtl/modelsim_transcript.png), [ModelSim waveform](../verification/simulation/rtl/modelsim_waveform.png), [Xcelium waveform](../verification/simulation/rtl/xcelium_waveform.png). The run finishes at time 665 in all three simulators. (ModelSim displays this as 665 ps because of its default time unit; the testbench has no `` `timescale ``.)

## 2. Exhaustive self-checking testbench (added)

[`verification/testbench/tb_divider_exhaustive.v`](../verification/testbench/tb_divider_exhaustive.v) was written during consolidation because the original testbench only prints results. It does not change the design.

| Check | Condition |
| ----- | --------- |
| Result | For every `x` in 0…255 and `y` in 1…255: `q == x / y`, `p == x % y` |
| Latency | `done` is 0 right after the `start` sampling edge, and rises exactly **9** rising edges later |
| Divide by zero | For every `x` with `y = 0`: `q == 0`, `p == x`, `done == 1` right after the sampling edge |
| Hold | `q`, `p`, `done` unchanged for 3 further edges with `start` low |
| Protocol | A `start` pulse (with different operands) 3 cycles into `DIVIDE` is ignored: 200 ÷ 7 still gives 28 r 4 |
| Reset | Asynchronous `rst` during `DIVIDE` clears `q`, `p`, `done` immediately, and the next division (255 ÷ 3) is correct |

Result:

```text
$ make -C verification exhaustive
Checked 65538 operations
TEST PASSED
```

**Mutation check.** To confirm the testbench can fail, it was run against two modified copies of the RTL in a scratch directory (not committed):

| Mutation | Result |
| -------- | ------ |
| `count < 8` → `count < 7` (one iteration short) | TEST FAILED (130,307 errors) |
| divide-by-zero `p <= x` → `p <= 0` | TEST FAILED (255 errors) |

## 3. Coverage (Cadence IMC)

[Capture](../verification/simulation/rtl/imc_coverage.png) of the directed test:

| Metric | Value |
| ------ | ----: |
| Overall average grade | 82.9 % |
| `tb_eight_bit_divider.dut` | 83.86 % (92 / 119) |
| Block | 92.86 % |
| Toggle | 69.31 % |
| FSM (`state`) | 87.5 % (6 / 7 = 85.71 % covered items) |
| Statement, expression | n/a (not collected) |

The FSM gap is consistent with the RTL: `IDLE` is never re-entered after the first `start`, and the `default` branch is unreachable.

## 4. Gate-level simulation

- Testbench: [`verification/gls/tb_eight_bit_divider_gls.v`](../verification/gls/tb_eight_bit_divider_gls.v). It has the same stimulus as the directed RTL testbench, plus `$sdf_annotate("./outputs/delays.sdf", tb_eight_bit_divider.dut, , "sdf.log", "MAXIMUM")`. It came from the source repository, where it was transcribed from the Task-3 lab report with two fixes (`End` → `end`, scope `.DUT` → `.dut`).
- Command ([`run_gls`](../verification/gls/run_gls)): `xrun -timescale 1ns/10ps -f filelist_gls -access +rwc -gui`. `filelist_gls` was not preserved; it must list the Genus netlist (`divider_netlist.v`), the standard-cell Verilog models and the GLS testbench ([capture](../verification/gls/reports/01_run_gls_script.png)).
- SDF: written by Genus `write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge -setuphold split`.

Results ([overview waveform](../verification/gls/reports/02_waveforms.png)):

- All six operations produce the expected `q`/`p`, with `done` 9 edges after the sampling edge. For 55 ÷ 0, `p = 0x37` and `done` stays high.
- Clock edge at 145,000 ps ([capture](../verification/gls/reports/03_clk_delay.png)): `done` rises at 145,047 ps → **47 ps** ([capture](../verification/gls/reports/04_done_delay.png)). `q = 0x04`, `p = 0x01` at 145,125 ps → **125 ps** clock-to-output ([capture](../verification/gls/reports/05_output_delay.png)).

Limitations: the GLS testbench is not self-checking. The netlist and SDF files are not stored, and the synthesis clock period of that netlist is not recorded.

## 5. Logical equivalence check

Dofile: [`verification/lec/divider_lec.do`](../verification/lec/divider_lec.do) ([original capture](../verification/lec/reports/06_lec_do_file.png)).

- Library: `slow_vdd1v0_basicCells{,_lvt,_hvt}.v`
- Golden: `fv/eight_bit_divider/fv_map.v.gz` (Genus intermediate netlist)
- Revised: `divider_netlist.v` (final Genus netlist)
- Flatten options: `-seq_constant`, `-seq_constant_x_to 0`, `-nodff_to_dlat_zero`, `-nodff_to_dlat_feedback`, `-hier_seq_merge`, `-gated_clock`

Result ([1](../verification/lec/reports/07_lec_output_1.png), [2](../verification/lec/reports/08_lec_output_2.png)): 64 compared points = 17 primary outputs + 47 DFFs, all equivalent. 0 non-equivalent, 0 aborted, 0 not compared. **Compare Results: PASS**. All primary outputs mapped and no unmapped DFF/DLAT.

**Scope:** this is a netlist-to-netlist check inside the synthesis flow. An RTL-to-netlist check was prepared but not run: the Genus script writes `rtl_to_final.tcl` via `write_do_lec -golden_design rtl`, but no result for it exists.
