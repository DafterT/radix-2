`timescale 1ns/1ps

module radix2_top
#(
    parameter int FFT_N      = 64,
    parameter int FRAC_BITS  = 14,
    parameter int TW_W       = 16,
    parameter int ROUND_OWID = 18,
    parameter int OUT_W      = 16
)
(
    input  logic              clk,
    input  logic              rst,
    input  logic signed [31:0] iq,
    input  logic              valid_i,
    input  logic              last_i,
    output logic signed [15:0] im,
    output logic signed [15:0] re,
    output logic              valid_o
);

    localparam int VALID_LATENCY = 5;
    localparam int ADDR_W        = $clog2(FFT_N / 2);

    logic                       iq_aligned_vld;
    logic signed [31:0]         iq_aligned;
    logic [ADDR_W-1:0]          twiddle_addr;
    logic signed [2*TW_W-1:0]   twiddle_rom;
    logic signed [31:0]         twiddle_mul;
    logic signed [31:0]         mul_re;
    logic signed [31:0]         mul_im;
    logic signed [ROUND_OWID-1:0] round_re;
    logic signed [ROUND_OWID-1:0] round_im;
    logic [VALID_LATENCY-1:0]   valid_pipe;

    initial begin
        if (FRAC_BITS != 14)
            $fatal(1, "radix2_top: FRAC_BITS must be 14 to match complex_mul_3dsp Q2.14 input");

        if (TW_W != 16)
            $fatal(1, "radix2_top: TW_W must be 16 to match complex_mul_3dsp packed twiddle input");

        if (OUT_W != 16)
            $fatal(1, "radix2_top: OUT_W must be 16 for the current top-level interface");
    end

    shift_register_with_valid #(
        .width(32),
        .depth(1)
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
        .FFT_N    (FFT_N),
        .FRAC_BITS(FRAC_BITS),
        .TW_W     (TW_W)
    ) u_rom (
        .clk (clk),
        .addr(twiddle_addr),
        .w   (twiddle_rom)
    );

    assign twiddle_mul = twiddle_rom;

    complex_mul_3dsp u_mul (
        .clk   (clk),
        .rst   (rst),
        .x     (iq_aligned),
        .y     (twiddle_mul),
        .out_re(mul_re),
        .out_im(mul_im)
    );

    convergent_rounding #(
        .IWID(32),
        .OWID(ROUND_OWID)
    ) u_round_re (
        .i_data(mul_re),
        .o_data(round_re)
    );

    convergent_rounding #(
        .IWID(32),
        .OWID(ROUND_OWID)
    ) u_round_im (
        .i_data(mul_im),
        .o_data(round_im)
    );

    symmetric_clip #(
        .IWID(ROUND_OWID),
        .OWID(OUT_W)
    ) u_clip_re (
        .i_data(round_re),
        .o_data(re)
    );

    symmetric_clip #(
        .IWID(ROUND_OWID),
        .OWID(OUT_W)
    ) u_clip_im (
        .i_data(round_im),
        .o_data(im)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_pipe <= '0;
        end else begin
            valid_pipe[0] <= valid_i;
            for (int i = 1; i < VALID_LATENCY; i++)
                valid_pipe[i] <= valid_pipe[i-1];
        end
    end

    assign valid_o = valid_pipe[VALID_LATENCY - 1];

endmodule
