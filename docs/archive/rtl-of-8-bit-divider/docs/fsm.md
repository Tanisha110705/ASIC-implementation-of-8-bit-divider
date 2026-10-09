# Control Sequencing (FSM)

> **Status.** The controller's state names, encoding and transition conditions are defined in the RTL, which is not in this repository. This document does **not** invent state names. It records the control behaviour seen at the ports in gate-level simulation. The state-level sections below are to be filled in once the RTL is added.

## 1. Observed handshake

![Observed start-to-done timing for 13 ÷ 3](../assets/cycle-operation.svg)

*Redrawn from the SimVision gate-level waveform ([original capture](../assets/gls-waveform-overview.png)). This is a derived diagram, not raw simulator output.*

```mermaid
sequenceDiagram
    participant TB as Testbench
    participant DUT as eight_bit_divider
    TB->>DUT: drive x, y; start = 1 (one clock)
    Note over DUT: edge E0 samples start<br/>done → 0, q/p → 0x00
    Note over DUT: edges 1 … 8: iterate (no port activity)
    DUT-->>TB: edge 9: done → 1, q and p valid
    Note over DUT,TB: done, q, p held until next start is sampled
    TB->>DUT: next x, y; start = 1
    Note over DUT: E0′: done → 0, q/p → 0x00
```

## 2. Cycle-by-cycle behaviour at the ports (13 ÷ 3)

Times come from the gate-level waveform (10 ns clock).

| Rising edge | Time | `start` | `done` | `q` | `p` | What is visible |
| ----------- | ---- | ------- | ------ | --- | --- | --------------- |
| E0 | 55 ns | 1 (sampled) | 0 | 0x00 | 0x00 | Operation accepted |
| 1 – 8 | 65 – 135 ns | 0 | 0 | 0x00 | 0x00 | Internal iteration; outputs unchanged |
| 9 | 145 ns | 0 | **1** (+47 ps) | **0x04** (+125 ps) | **0x01** (+125 ps) | Result valid |
| 10 | 155 ns | 0 | 1 | 0x04 | 0x01 | Result held |
| E0′ | 165 ns | 1 (sampled) | 0 | 0x00 | 0x00 | Next operation accepted (100 ÷ 7) |
| E0′ + 9 | 255 ns | 0 | 1 | 0x0E | 0x02 | Result valid |

Each of the five non-zero-divisor tests shows the same 9-edge latency.

### Divide-by-zero (55 ÷ 0)

| Rising edge | Time | `start` | `done` | `q` | `p` |
| ----------- | ---- | ------- | ------ | --- | --- |
| previous op complete | 585 ns | 0 | 1 | 0x4D | 0x00 |
| E0 | 605 ns | 1 (sampled) | 1 (stays high) | **0x00** | **0x37** (= x) |

With `y = 0` the netlist skips the multi-cycle sequence. It returns `q = 0`, `p = x` on the sampling edge, and `done` never deasserts. This points to a dedicated zero-divisor branch in the controller, but the branch condition needs the RTL to confirm.

## 3. On "8-cycle operation"

The project describes the divider as completing in 8 cycles. One operation per quotient bit of an 8-bit divider is the natural reading of that. The gate-level waveform shows **9** rising edges from the `start`-sampling edge to `done`. Both can be true at once if one edge is spent loading operands or registering the result and 8 edges run the iterations. The RTL is needed to confirm that split.

## 4. State-by-state description

To be completed from the RTL. For each state, record:

| State (RTL name) | Purpose | Entry condition | Registers updated | Outputs | Next state(s) |
| ---------------- | ------- | --------------- | ----------------- | ------- | ------------- |
| *pending RTL* | | | | | |

When the RTL is added, also add a state diagram as `assets/fsm.svg` and a Mermaid `stateDiagram-v2` block here, using the state names exactly as written in the RTL.
