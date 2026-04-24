`timescale 1ns/1ps

module delay_line_with_valid
#(
    parameter int WIDTH = 8,
    parameter int DEPTH = 8
)
(
    input  logic               clk,
    input  logic               rst,

    input  logic               in_vld,
    input  logic [WIDTH - 1:0] in_data,

    output logic               out_vld,
    output logic [WIDTH - 1:0] out_data
);

    logic [WIDTH - 1:0] data_q [0:DEPTH - 1];
    logic [DEPTH - 1:0] valid_q;

    initial begin
        if (WIDTH <= 0)
            $fatal(1, "delay_line_with_valid: WIDTH must be > 0");

        if (DEPTH <= 0)
            $fatal(1, "delay_line_with_valid: DEPTH must be > 0");
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < DEPTH; i++) begin
                data_q[i] <= '0;
            end
        end else begin
            if (in_vld)
                data_q[0] <= in_data;

            for (int i = 1; i < DEPTH; i++) begin
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

            for (int i = 1; i < DEPTH; i++) begin
                valid_q[i] <= valid_q[i - 1];
            end
        end
    end

    assign out_data = data_q[DEPTH - 1];
    assign out_vld  = valid_q[DEPTH - 1];

endmodule
