`timescale 1ns/1ps

module shift_register
#(
    parameter int width = 8,
    parameter int depth = 8
)
(
    input  logic               clk,
    input  logic               rst,
    input  logic [width - 1:0] in_data,
    output logic [width - 1:0] out_data
);

    initial begin
        if (width <= 0)
            $fatal(1, "shift_register: width must be > 0");

        if (depth <= 0)
            $fatal(1, "shift_register: depth must be > 0");
    end

    logic [width - 1:0] data_q [0:depth - 1];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < depth; i++)
                data_q[i] <= '0;
        end else begin
            data_q[0] <= in_data;

            for (int i = 1; i < depth; i++)
                data_q[i] <= data_q[i - 1];
        end
    end

    assign out_data = data_q[depth - 1];

endmodule
