`timescale 1ns/1ps

import radix2_types_pkg::*;

module radix2_top
#(
    parameter int FFT_N = 64
)
(
    input  logic        clk,
    input  logic        rst,
    input  complex16_t  iq,
    input  logic        valid_i,
    input  logic        last_i,
    output complex16_t  iq_o,
    output logic        valid_o
);

    localparam int IQ_COMP_W         = $bits(complex16_comp_t);
    localparam int PACKED_COMPLEX_W  = $bits(complex16_t);
    localparam int INPUT_ALIGN_DEPTH = 1;
    localparam int VALID_PIPE_STAGES = 4;
    localparam int ADDR_W            = ((FFT_N / 2) > 1) ? $clog2(FFT_N / 2) : 1;
    localparam int OUT_W             = 16;
    localparam int TW_W              = $bits(complex16_comp_t);
    localparam int TW_FRAC_W         = TW_W - 2;
    localparam int CMUL_TERM_W       = IQ_COMP_W + TW_W;
    localparam int CMUL_SUM_GROWTH_W = 1;
    localparam int MUL_OUT_W         = CMUL_TERM_W + CMUL_SUM_GROWTH_W;
    localparam int ROUND_OWID        = MUL_OUT_W - TW_FRAC_W;

    logic                         iq_aligned_vld;
    complex16_t                   iq_aligned;
    logic [ADDR_W-1:0]            twiddle_addr;
    complex16_t                   twiddle_rom;
    complex16_t                   twiddle_mul;
    complex33_t                   mul;
    logic signed [ROUND_OWID-1:0] round_re;
    logic signed [ROUND_OWID-1:0] round_im;
    complex16_comp_t              re_clip;
    complex16_comp_t              im_clip;
    logic [VALID_PIPE_STAGES-1:0] valid_pipe;

    shift_register_with_valid #(
        .WIDTH(PACKED_COMPLEX_W),
        .DEPTH(INPUT_ALIGN_DEPTH)
    ) u_input_delay (
        .clk     (clk),
        .rst     (rst),
        .in_vld  (valid_i),
        .in_data (iq),
        .out_vld (iq_aligned_vld),
        .out_data(iq_aligned)
    );

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
    ) u_rom (
        .clk (clk),
        .addr(twiddle_addr),
        .w   (twiddle_rom)
    );

    assign twiddle_mul = twiddle_rom;

    complex_mul_3dsp u_mul (
        .clk (clk),
        .rst (rst),
        .x   (iq_aligned),
        .y   (twiddle_mul),
        .out (mul)
    );

    convergent_rounding #(
        .IWID(MUL_OUT_W),
        .OWID(ROUND_OWID)
    ) u_round_re (
        .i_data(mul.re),
        .o_data(round_re)
    );

    convergent_rounding #(
        .IWID(MUL_OUT_W),
        .OWID(ROUND_OWID)
    ) u_round_im (
        .i_data(mul.im),
        .o_data(round_im)
    );

    symmetric_clip #(
        .IWID(ROUND_OWID),
        .OWID(OUT_W)
    ) u_clip_re (
        .i_data(round_re),
        .o_data(re_clip)
    );

    symmetric_clip #(
        .IWID(ROUND_OWID),
        .OWID(OUT_W)
    ) u_clip_im (
        .i_data(round_im),
        .o_data(im_clip)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_pipe <= '0;
        end else begin
            valid_pipe[0] <= iq_aligned_vld;
            for (int i = 1; i < VALID_PIPE_STAGES; i++)
                valid_pipe[i] <= valid_pipe[i-1];
        end
    end

    assign valid_o = valid_pipe[VALID_PIPE_STAGES - 1];
    assign iq_o = radix2_types_pkg::comp_t_to_complex16(re_clip, im_clip);

endmodule
