`timescale 1ns/1ps

import radix2_types_pkg::*;

module radix2_fft_stage #(
    parameter int FFT_N = 64
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       valid_i,
    input  logic       last_i,
    input  complex16_t a_i,     // Q16.0
    input  complex16_t b_i,     // Q16.0
    output logic       valid_o,
    output logic       last_o,
    output complex16_t a_o,     // Q16.0
    output complex16_t b_o      // Q16.0
);

    initial begin
        if (FFT_N < 2)
            $fatal(1, "radix2_fft_stage: FFT_N must be >= 2");

        if ((FFT_N & (FFT_N - 1)) != 0)
            $fatal(1, "radix2_fft_stage: FFT_N must be power of two");
    end

    localparam int TW_W              = $bits(complex16_comp_t);
    localparam int DEPTH             = FFT_N / 2;
    localparam int ADDR_W            = (DEPTH > 1) ? $clog2(DEPTH) : 1;
    localparam int AB_WIDTH          = 2 * $bits(complex16_t);
    localparam int INPUT_ALIGN_DEPTH = 1;
    localparam int BUTTERFLY_LATENCY = 8;
    localparam int LAST_ALIGN_DEPTH  = INPUT_ALIGN_DEPTH + BUTTERFLY_LATENCY;

    logic                ab_aligned_vld;
    logic [AB_WIDTH-1:0] ab_aligned_data;
    complex16_t          a_aligned;
    complex16_t          b_aligned;
    logic [ADDR_W-1:0]   twiddle_addr;
    complex16_t          twiddle_w;
    logic                butterfly_valid_o;
    complex16_t          butterfly_a_o;
    complex16_t          butterfly_b_o;
    logic                last_aligned;

    shift_register_with_valid #(
        .WIDTH(AB_WIDTH),
        .DEPTH(INPUT_ALIGN_DEPTH)
    ) u_ab_align (
        .clk     (clk),
        .rst     (rst),
        .in_vld  (valid_i),
        .in_data ({a_i, b_i}),
        .out_vld (ab_aligned_vld),
        .out_data(ab_aligned_data)
    );

    assign {a_aligned, b_aligned} = ab_aligned_data;

    radix2_cu #(
        .FFT_N(FFT_N)
    ) u_cu (
        .clk    (clk),
        .rst    (rst),
        .valid_i(valid_i),
        .last_i (last_i),
        .addr_o (twiddle_addr)
    );

    fft_twiddle_rom #(
        .FFT_N(FFT_N),
        .TW_W (TW_W)
    ) u_twiddle_rom (
        .clk (clk),
        .addr(twiddle_addr),
        .w   (twiddle_w)
    );

    radix2_butterfly u_butterfly (
        .clk    (clk),
        .rst    (rst),
        .valid_i(ab_aligned_vld),
        .a      (a_aligned),
        .b      (b_aligned),
        .W      (twiddle_w),
        .valid_o(butterfly_valid_o),
        .a_out  (butterfly_a_o),
        .b_out  (butterfly_b_o)
    );

    shift_register #(
        .WIDTH(1),
        .DEPTH(LAST_ALIGN_DEPTH)
    ) u_last_align (
        .clk     (clk),
        .rst     (rst),
        .in_data (last_i),
        .out_data(last_aligned)
    );

    assign valid_o = butterfly_valid_o;
    assign last_o  = butterfly_valid_o ? last_aligned : 1'b0;
    assign a_o     = butterfly_a_o;
    assign b_o     = butterfly_b_o;

endmodule
