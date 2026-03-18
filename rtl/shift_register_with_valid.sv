`timescale 1ns/1ps

module shift_register_with_valid
# (
    parameter width = 8, depth = 8
)
(
    input  logic              clk,
    input  logic              rst,

    input  logic              in_vld,
    input  logic              [width - 1:0] in_data,

    output logic              out_vld,
    output logic              [width - 1:0] out_data
);

    logic [width - 1:0] data [0:depth - 1];
    logic valid [0:depth - 1];

    always_ff @ (posedge clk)
        if (rst) begin
            for (int i = 0; i < depth; i++) begin
                data[i] <= '0;
                valid[i] <= '0;
            end
        end
        else
        begin
            valid[0] <= in_vld;
            if (in_vld)
                data [0] <= in_data;

            for (int i = 1; i < depth; i ++) begin
                valid[i] <= valid[i - 1];
                if (valid[i - 1])
                    data [i] <= data [i - 1];
            end
        end

    assign out_data = data [depth - 1];
    assign out_vld = valid [depth - 1];
endmodule