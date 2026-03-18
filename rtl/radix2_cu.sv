`timescale 1ns/1ps

module radix2_cu
#(
    parameter int FFT_N = 64
)
(
    input  logic                       clk,
    input  logic                       rst,
    input  logic                       valid_i,
    input  logic                       last_i,
    output logic [$clog2(FFT_N/2)-1:0] addr_o
);

    localparam int DEPTH  = FFT_N / 2;
    localparam int ADDR_W = $clog2(DEPTH);

    logic [ADDR_W-1:0] addr_q;

    initial begin
        if (FFT_N < 4)
            $fatal(1, "radix2_cu: FFT_N must be >= 4");

        if ((FFT_N & (FFT_N - 1)) != 0)
            $fatal(1, "radix2_cu: FFT_N must be power of two");
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            addr_q <= '0;
        end else if (valid_i) begin
            if (last_i || (addr_q == ADDR_W'(DEPTH - 1)))
                addr_q <= '0;
            else
                addr_q <= addr_q + 1'b1;
        end
    end

    assign addr_o = addr_q;

endmodule
