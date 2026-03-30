`timescale 1ns/1ps

module radix2_fft_stage #(
    parameter int FFT_N = 64
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        valid_i,
    input  logic        last_i,
    input  logic [31:0] a_i,    // [31:16] = a_im (Q16.0), [15:0] = a_re (Q16.0)
    input  logic [31:0] b_i,    // [31:16] = b_im (Q16.0), [15:0] = b_re (Q16.0)
    output logic        valid_o,
    output logic        last_o,
    output logic [65:0] a_o,    // [65:33] = im (Q19.14), [32:0] = re (Q19.14)
    output logic [65:0] b_o     // [65:33] = im (Q19.14), [32:0] = re (Q19.14)
);

    initial begin
        if (FFT_N < 2)
            $fatal(1, "radix2_fft_stage: FFT_N must be >= 2");

        if ((FFT_N & (FFT_N - 1)) != 0)
            $fatal(1, "radix2_fft_stage: FFT_N must be power of two");
    end

    localparam int TW_W              = 16;
    localparam int TWIDDLE_PACK_W    = 2 * TW_W;
    localparam int DEPTH             = FFT_N / 2;
    localparam int ADDR_W            = (DEPTH > 1) ? $clog2(DEPTH) : 1;
    localparam int INPUT_ALIGN_DEPTH = 1;
    localparam int LAST_ALIGN_DEPTH  = 6;

    logic                      ab_aligned_vld;
    logic [63:0]               ab_aligned;
    logic [31:0]               a_aligned;
    logic [31:0]               b_aligned;
    logic [ADDR_W-1:0]         twiddle_addr;
    logic [TWIDDLE_PACK_W-1:0] twiddle_w;
    logic                      butterfly_valid_o;
    logic [65:0]               butterfly_a_o;
    logic [65:0]               butterfly_b_o;
    logic                      last_aligned;

    shift_register_with_valid #(
        .WIDTH(64),
        .DEPTH(INPUT_ALIGN_DEPTH)
    ) u_ab_align (
        .clk     (clk),
        .rst     (rst),
        .in_vld  (valid_i),
        .in_data ({a_i, b_i}),
        .out_vld (ab_aligned_vld),
        .out_data(ab_aligned)
    );

    assign a_aligned = ab_aligned[63:32];
    assign b_aligned = ab_aligned[31:0];

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
