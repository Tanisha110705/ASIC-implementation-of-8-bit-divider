// -----------------------------------------------------------------------------
// tb_divider_exhaustive.v
//
// Self-checking RTL testbench for eight_bit_divider (rtl/divider.v).
// Added during repository consolidation; complements the original directed
// testbench (tb_divider_8bit.v), which prints results but does not check them.
//
// Checks performed:
//   1. All 65,536 (x, y) operand pairs, including every y = 0 case:
//        y != 0 : q == x / y, p == x % y, and done rises exactly 9 rising
//                 clock edges after the edge that samples start
//                 (8 shift/subtract iterations + 1 result-load edge).
//        y == 0 : q == 0, p == x and done == 1 on the start-sampling edge.
//   2. Result hold: q, p and done stay stable for 3 further edges with
//      start low.
//   3. start asserted while DIVIDE is running is ignored.
//   4. Asynchronous reset in the middle of a division returns q, p and done
//      to 0, and the divider works normally afterwards.
//
// The testbench uses only Verilog-2001 constructs and no `timescale, so it
// runs unchanged on Icarus Verilog, Xcelium (-timescale 1ns/10ps) and ModelSim.
// It prints "TEST PASSED" or "TEST FAILED (<n> errors)".
// -----------------------------------------------------------------------------
module tb_divider_exhaustive;

    localparam CLK_HALF        = 5;   // 10-unit clock period
    localparam EXPECTED_LATENCY = 9;  // rising edges from start-sample to done

    reg clk, rst, start;
    reg [7:0] x, y;
    wire [7:0] q, p;
    wire done;

    integer errors;
    integer checks;
    integer i, j, k, cycles;
    reg [7:0] q_hold, p_hold;

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

    initial clk = 0;
    always #CLK_HALF clk = ~clk;

    // Apply one operand pair and check result, latency and hold behaviour.
    task check_division;
        input [7:0] dividend;
        input [7:0] divisor;
        begin
            @(negedge clk);
            x = dividend;
            y = divisor;
            start = 1;
            @(posedge clk);          // edge that samples start
            #1;
            @(negedge clk);
            start = 0;

            if (divisor == 0) begin
                if (done !== 1'b1 || q !== 8'd0 || p !== dividend) begin
                    errors = errors + 1;
                    if (errors <= 10)
                        $display("ERROR div-by-zero: x=%0d -> q=%0d p=%0d done=%b",
                                 dividend, q, p, done);
                end
            end else begin
                if (done !== 1'b0) begin
                    errors = errors + 1;
                    if (errors <= 10)
                        $display("ERROR: done not cleared after start (x=%0d y=%0d)",
                                 dividend, divisor);
                end
                cycles = 0;          // edges counted after the sampling edge
                while (done !== 1'b1 && cycles < 20) begin
                    @(posedge clk);
                    #1;
                    cycles = cycles + 1;
                end
                if (cycles != EXPECTED_LATENCY) begin
                    errors = errors + 1;
                    if (errors <= 10)
                        $display("ERROR latency: x=%0d y=%0d took %0d edges (expected %0d)",
                                 dividend, divisor, cycles, EXPECTED_LATENCY);
                end
                if (q !== dividend / divisor || p !== dividend % divisor) begin
                    errors = errors + 1;
                    if (errors <= 10)
                        $display("ERROR result: %0d / %0d -> q=%0d p=%0d (expected q=%0d p=%0d)",
                                 dividend, divisor, q, p,
                                 dividend / divisor, dividend % divisor);
                end
            end

            // Hold check: outputs must not change while start stays low.
            q_hold = q;
            p_hold = p;
            for (k = 0; k < 3; k = k + 1) begin
                @(posedge clk);
                #1;
                if (done !== 1'b1 || q !== q_hold || p !== p_hold) begin
                    errors = errors + 1;
                    if (errors <= 10)
                        $display("ERROR hold: x=%0d y=%0d outputs changed while idle",
                                 dividend, divisor);
                end
            end
            checks = checks + 1;
        end
    endtask

    initial begin
        errors = 0;
        checks = 0;
        rst = 1; start = 0; x = 0; y = 0;
        #50 rst = 0;

        // Reset values
        if (q !== 0 || p !== 0 || done !== 0) begin
            errors = errors + 1;
            $display("ERROR: outputs not zero after reset");
        end

        // 1 + 2: exhaustive operand sweep with latency and hold checks
        for (i = 0; i < 256; i = i + 1)
            for (j = 0; j < 256; j = j + 1)
                check_division(i[7:0], j[7:0]);

        // 3: start pulses during DIVIDE must be ignored
        @(negedge clk);
        x = 8'd200; y = 8'd7; start = 1;
        @(negedge clk);
        start = 0;
        repeat (3) @(negedge clk);
        x = 8'd9; y = 8'd2; start = 1;       // should be ignored
        @(negedge clk);
        start = 0;
        x = 8'd0; y = 8'd0;
        wait (done === 1'b1);
        #1;
        if (q !== 8'd28 || p !== 8'd4) begin
            errors = errors + 1;
            $display("ERROR: start during DIVIDE was not ignored (q=%0d p=%0d)", q, p);
        end
        checks = checks + 1;

        // 4: asynchronous reset in the middle of a division
        @(negedge clk);
        x = 8'd255; y = 8'd3; start = 1;
        @(negedge clk);
        start = 0;
        repeat (3) @(negedge clk);
        #2 rst = 1;
        #1;
        if (q !== 0 || p !== 0 || done !== 0) begin
            errors = errors + 1;
            $display("ERROR: async reset during DIVIDE did not clear outputs");
        end
        @(negedge clk);
        rst = 0;
        check_division(8'd255, 8'd3);       // must work normally after reset

        $display("Checked %0d operations", checks);
        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED (%0d errors)", errors);
        $finish;
    end

endmodule
