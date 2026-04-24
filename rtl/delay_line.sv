`timescale 1ns/1ps

module delay_line
#(
    parameter int WIDTH = 8,
    parameter int DEPTH = 8
)
(
    input  logic               clk,
    input  logic               rst,
    input  logic [WIDTH - 1:0] in_data,
    output logic [WIDTH - 1:0] out_data
);

    initial begin
        if (WIDTH <= 0)
            $fatal(1, "delay_line: WIDTH must be > 0");

        if (DEPTH <= 0)
            $fatal(1, "delay_line: DEPTH must be > 0");
    end

    logic [WIDTH - 1:0] data_q [0:DEPTH - 1];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < DEPTH; i++)
                data_q[i] <= '0;
        end else begin
            data_q[0] <= in_data;

            for (int i = 1; i < DEPTH; i++)
                data_q[i] <= data_q[i - 1];
        end
    end

    assign out_data = data_q[DEPTH - 1];

endmodule
