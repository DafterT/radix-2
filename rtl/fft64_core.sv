`timescale 1ns/1ps

import complex_fixed_pkg::*;

module fft64_core
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
    localparam int DEPTH     = FFT_N / 2;
    localparam int ADDR_W    = $clog2(DEPTH);

    logic [TW_ADDR_W-1:0] twiddle_addr;
    complex16_t           twiddle_w;
    logic                 cu_bfly_valid;
    complex16_t           cu_bfly_a;
    complex16_t           cu_bfly_b;
    logic                 bfly_valid;
    complex16_t           bfly_a;
    complex16_t           bfly_b;
    logic                 bank0_we_a;
    logic [ADDR_W-1:0]    bank0_addr_a;
    logic [TDATA_W-1:0]   bank0_din_a;
    logic                 bank0_re_b;
    logic [ADDR_W-1:0]    bank0_addr_b;
    logic [TDATA_W-1:0]   bank0_dout_b;
    logic                 bank1_we_a;
    logic [ADDR_W-1:0]    bank1_addr_a;
    logic [TDATA_W-1:0]   bank1_din_a;
    logic                 bank1_re_b;
    logic [ADDR_W-1:0]    bank1_addr_b;
    logic [TDATA_W-1:0]   bank1_dout_b;

    initial begin
        if (TDATA_W != $bits(complex16_t))
            $fatal(1, "fft64_core: TDATA_W must be %0d", $bits(complex16_t));
    end

    fft64_controller #(
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
        .bfly_b_i     (bfly_b),
        .bank0_we_a   (bank0_we_a),
        .bank0_addr_a (bank0_addr_a),
        .bank0_din_a  (bank0_din_a),
        .bank0_re_b   (bank0_re_b),
        .bank0_addr_b (bank0_addr_b),
        .bank0_dout_b (bank0_dout_b),
        .bank1_we_a   (bank1_we_a),
        .bank1_addr_a (bank1_addr_a),
        .bank1_din_a  (bank1_din_a),
        .bank1_re_b   (bank1_re_b),
        .bank1_addr_b (bank1_addr_b),
        .bank1_dout_b (bank1_dout_b)
    );

    simple_dual_port_ram #(
        .DEPTH(DEPTH),
        .WIDTH(TDATA_W)
    ) u_bank0_ram (
        .clk  (clk),
        .we   (bank0_we_a),
        .waddr(bank0_addr_a),
        .din  (bank0_din_a),
        .re   (bank0_re_b),
        .raddr(bank0_addr_b),
        .dout (bank0_dout_b)
    );

    simple_dual_port_ram #(
        .DEPTH(DEPTH),
        .WIDTH(TDATA_W)
    ) u_bank1_ram (
        .clk  (clk),
        .we   (bank1_we_a),
        .waddr(bank1_addr_a),
        .din  (bank1_din_a),
        .re   (bank1_re_b),
        .raddr(bank1_addr_b),
        .dout (bank1_dout_b)
    );

    twiddle_rom #(
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
