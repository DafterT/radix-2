`timescale 1ns/1ps

module radix2_top
#(
    parameter int FFT_N      = 64,
    parameter int ROUND_OWID = 18
)
(
    input  logic               clk,
    input  logic               rst,
    input  logic        [31:0] iq,
    input  logic               valid_i,
    input  logic               last_i,
    output logic signed [15:0] im,
    output logic signed [15:0] re,
    output logic               valid_o
);

    localparam int PACKED_COMPLEX_W  = 32;
    localparam int MUL_OUT_W         = PACKED_COMPLEX_W;
    localparam int INPUT_ALIGN_DEPTH = 1;
    localparam int VALID_PIPE_STAGES = 4;
    localparam int ADDR_W            = $clog2(FFT_N / 2);
    localparam int OUT_W             = 16;
    localparam int FRAC_BITS         = 14;
    localparam int TW_W              = 16;
    localparam int TWIDDLE_PACK_W    = 2 * TW_W;

    logic                                iq_aligned_vld;
    logic        [PACKED_COMPLEX_W-1:0]  iq_aligned;
    logic        [ADDR_W-1:0]            twiddle_addr;
    logic        [TWIDDLE_PACK_W-1:0]    twiddle_rom;
    logic        [PACKED_COMPLEX_W-1:0]  twiddle_mul;
    logic signed [MUL_OUT_W-1:0]         mul_re;
    logic signed [MUL_OUT_W-1:0]         mul_im;
    logic signed [ROUND_OWID-1:0]        round_re;
    logic signed [ROUND_OWID-1:0]        round_im;
    logic        [VALID_PIPE_STAGES-1:0] valid_pipe;

    shift_register_with_valid #(
        .width(PACKED_COMPLEX_W),
        .depth(INPUT_ALIGN_DEPTH)
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
        .IWID(MUL_OUT_W),
        .OWID(ROUND_OWID)
    ) u_round_re (
        .i_data(mul_re),
        .o_data(round_re)
    );

    convergent_rounding #(
        .IWID(MUL_OUT_W),
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
            valid_pipe[0] <= iq_aligned_vld;
            for (int i = 1; i < VALID_PIPE_STAGES; i++)
                valid_pipe[i] <= valid_pipe[i-1];
        end
    end

    assign valid_o = valid_pipe[VALID_PIPE_STAGES - 1];

endmodule
