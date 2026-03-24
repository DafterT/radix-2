`timescale 1ns/1ps

module radix2_cu
#(
    parameter  int FFT_N  = 64,
    localparam int DEPTH  = FFT_N / 2,
    localparam int ADDR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1
)
(
    input  logic              clk,
    input  logic              rst,
    input  logic              valid_i,
    input  logic              last_i,
    output logic [ADDR_W-1:0] addr_o
);

    initial begin
        if (FFT_N < 2)
            $fatal(1, "radix2_cu: FFT_N must be >= 2");

        if ((FFT_N & (FFT_N - 1)) != 0)
            $fatal(1, "radix2_cu: FFT_N must be power of two");
    end

    localparam logic [ADDR_W-1:0] LAST_ADDR = DEPTH - 1;

    logic [ADDR_W-1:0] addr_q;

    always_ff @(posedge clk) begin
        if (rst) begin
            addr_q <= '0;
        end else if (valid_i) begin
            if (last_i || (addr_q == LAST_ADDR))
                addr_q <= '0;
            else
                addr_q <= addr_q + 1'b1;
        end
    end

    assign addr_o = addr_q;

endmodule
