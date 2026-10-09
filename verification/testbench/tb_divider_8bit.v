module tb_eight_bit_divider;
    reg clk, rst, start;
    reg [7:0] x, y;
    wire [7:0] q, p;
    wire done;

    // Instantiate the divider module
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

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Verilog-style task declaration
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
        // Initialize all signals
        rst = 1; start = 0; x = 0; y = 0;
        #50 rst = 0;

        // Run multiple division cases
        run_division(13, 3);
        run_division(100, 7);
        run_division(50, 5);
        run_division(200, 15);
        run_division(77, 1);
        run_division(55, 0);

        #50 $finish;
    end
endmodule
