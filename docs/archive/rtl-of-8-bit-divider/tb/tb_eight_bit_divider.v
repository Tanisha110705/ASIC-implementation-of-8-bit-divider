// -----------------------------------------------------------------------------
// tb_eight_bit_divider.v
//
// Directed gate-level simulation (GLS) testbench for the eight_bit_divider
// netlist. Transcribed from the project's GLS/LEC lab report. Two transcription
// fixes were applied:
//   * `End` -> `end` (word-processor auto-capitalisation in the report).
//   * The $sdf_annotate scope is written as `tb_eight_bit_divider.dut` to match
//     the instance name below (the report text reads `.DUT`; Verilog
//     hierarchical names are case-sensitive).
//
// Protocol exercised (as observed in the GLS waveform):
//   1. Drive x (dividend) and y (divisor) and pulse `start` for one clock.
//   2. Wait for `done`, then read q (quotient) and p (remainder).
//
// The testbench prints results; it does not compare them against expected
// values automatically. Results were checked by waveform inspection
// (see docs/verification.md).
//
// Timescale is supplied on the command line: xrun -timescale 1ns/10ps
// -----------------------------------------------------------------------------
module tb_eight_bit_divider;

reg clk, rst, start;
reg [7:0] x, y;
wire [7:0] q, p;
wire done;

eight_bit_divider dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .x(x),
    .y(y),
    .q(q),
    .p(p),
    .done(done)
);

// 10 ns clock period (100 MHz). This is a functional GLS clock, not the
// synthesis timing target.
initial clk = 0;
always #5 clk = ~clk;

// Back-annotate cell/interconnect delays written by Genus (write_sdf).
initial
begin
    $sdf_annotate("./outputs/delays.sdf", tb_eight_bit_divider.dut, , "sdf.log", "MAXIMUM");
end

// Apply one operand pair, pulse start for one cycle and wait for completion.
task run_division;
    input [7:0] dividend;
    input [7:0] divisor;
    begin
        @(negedge clk);
        x = dividend;
        y = divisor;
        start = 1;
        @(negedge clk);
        start = 0;
        wait(done);
        @(posedge clk);
        $display("Dividend=%0d, Divisor=%0d --> Quotient=%0d, Remainder=%0d",
                 dividend, divisor, q, p);
    end
endtask

initial begin
    rst = 1; start = 0; x = 0; y = 0;
    #50 rst = 0;
    run_division(13, 3);
    run_division(100, 7);
    run_division(50, 5);
    run_division(200, 15);
    run_division(77, 1);
    run_division(55, 0);    // divide-by-zero case
    #50 $finish;
end

endmodule
