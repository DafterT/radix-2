`timescale 1ns/1ps

module shift_register_with_valid
#(
    parameter int width = 8,
    parameter int depth = 8
)
(
    input  logic               clk,
    input  logic               rst,

    input  logic               in_vld,
    input  logic [width - 1:0] in_data,

    output logic               out_vld,
    output logic [width - 1:0] out_data
);

    logic [width - 1:0] data_q [0:depth - 1];
    logic [depth - 1:0] valid_q;

    initial begin
        if (width <= 0)
            $fatal(1, "shift_register_with_valid: width must be > 0");

        if (depth <= 0)
            $fatal(1, "shift_register_with_valid: depth must be > 0");
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < depth; i++) begin
                data_q[i] <= '0;
            end
        end else begin
            if (in_vld)
                data_q[0] <= in_data;

            for (int i = 1; i < depth; i++) begin
                if (valid_q[i - 1])
                    data_q[i] <= data_q[i - 1];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_q <= '0;
        end else begin
            valid_q[0] <= in_vld;

            for (int i = 1; i < depth; i++) begin
                valid_q[i] <= valid_q[i - 1];
            end
        end
    end

    assign out_data = data_q[depth - 1];
    assign out_vld  = valid_q[depth - 1];

endmodule
