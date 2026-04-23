`timescale 1ns/1ps

import radix2_types_pkg::*;

module radix2_fft64
#(
    parameter int TDATA_W = 32
)
(
    input  logic               clk,
    input  logic               rst,
    input  logic [TDATA_W-1:0] s_axis_tdata,
    input  logic               s_axis_tvalid,
    output logic               s_axis_tready,
    output logic [TDATA_W-1:0] m_axis_tdata,
    output logic               m_axis_tvalid,
    input  logic               m_axis_tready
);

    localparam int FFT_N     = 64;
    localparam int TW_W      = $bits(complex16_comp_t);
    localparam int TW_ADDR_W = $clog2(FFT_N / 2);

    logic [TW_ADDR_W-1:0] twiddle_addr;
    complex16_t           twiddle_w;
    logic                 cu_bfly_valid;
    complex16_t           cu_bfly_a;
    complex16_t           cu_bfly_b;
    logic                 bfly_valid;
    complex16_t           bfly_a;
    complex16_t           bfly_b;

    initial begin
        if (TDATA_W != $bits(complex16_t))
            $fatal(1, "radix2_fft64: TDATA_W must be %0d", $bits(complex16_t));
    end

    radix2_cu #(
        .TDATA_W(TDATA_W)
    ) u_cu (
        .clk          (clk),
        .rst          (rst),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata (m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .twiddle_addr_o(twiddle_addr),
        .bfly_valid_o (cu_bfly_valid),
        .bfly_a_o     (cu_bfly_a),
        .bfly_b_o     (cu_bfly_b),
        .bfly_valid_i (bfly_valid),
        .bfly_a_i     (bfly_a),
        .bfly_b_i     (bfly_b)
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
        .valid_i(cu_bfly_valid),
        .a      (cu_bfly_a),
        .b      (cu_bfly_b),
        .W      (twiddle_w),
        .valid_o(bfly_valid),
        .a_out  (bfly_a),
        .b_out  (bfly_b)
    );

endmodule
