module eight_bit_divider (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] x, // dividend
    input wire [7:0] y, // divisor
    output reg [7:0] q, // quotient
    output reg [7:0] p, // remainder
    output reg done
);
    reg [7:0] a, b;
    reg [8:0] c;
    reg [3:0] count;
    reg [1:0] state;

    // Declare temporary next state registers
    reg [8:0] c_next;
    reg [7:0] a_next;
    reg done_next;
    reg [1:0] state_next;
    reg [3:0] count_next;

    localparam IDLE = 2'b00,
               DIVIDE = 2'b01,
               DONE = 2'b10;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            q <= 0;
            p <= 0;
            a <= 0;
            b <= 0;
            c <= 0;
            count <= 0;
            state <= IDLE;
            done <= 0;
        end else begin
            // Default next states
            a_next = a;
            c_next = c;
            count_next = count;
            state_next = state;
            done_next = done;

            case (state)
                IDLE: begin
                    done_next = 0;
                    if (start) begin
                        if (y == 0) begin
                            q <= 0;
                            p <= x;
                            done_next = 1;
                            state_next = DONE;
                        end else begin
                            a_next = x;
                            b <= y;
                            c_next = 0;
                            count_next = 0;
                            q <= 0;
                            p <= 0;
                            done_next = 0;
                            state_next = DIVIDE;
                        end
                    end
                end
                DIVIDE: begin
                    if (count < 8) begin
                        c_next = {c[7:0], a[7]};
                        a_next = {a[6:0], 1'b0};
                        c_next = c_next - {1'b0, b};
                        if (c_next[8]) begin
                            a_next[0] = 0;
                            c_next = c_next + {1'b0, b};
                        end else begin
                            a_next[0] = 1;
                        end
                        count_next = count + 1;
                    end else begin
                        q <= a;
                        p <= c[7:0];
                        done_next = 1;
                        state_next = DONE;
                    end
                end
                DONE: begin
                    done_next = 1;
                    if (start) begin
                        if (y == 0) begin
                            q <= 0;
                            p <= x;
                            done_next = 1;
                            state_next = DONE;
                        end else begin
                            a_next = x;
                            b <= y;
                            c_next = 0;
                            count_next = 0;
                            q <= 0;
                            p <= 0;
                            done_next = 0;
                            state_next = DIVIDE;
                        end
                    end
                end
                default: state_next = IDLE;
            endcase

            a <= a_next;
            c <= c_next;
            count <= count_next;
            state <= state_next;
            done <= done_next;
        end
    end
endmodule

