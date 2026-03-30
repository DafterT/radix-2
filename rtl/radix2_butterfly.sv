`timescale 1ns/1ps

module radix2_butterfly (
    input  logic        clk,
    input  logic        rst,
    input  logic        valid_i,
    input  logic [31:0] a,     // [31:16] = a_im (Q16.0), [15:0] = a_re (Q16.0)
    input  logic [31:0] b,     // [31:16] = b_im (Q16.0), [15:0] = b_re (Q16.0)
    input  logic [31:0] W,     // [31:16] = W_im (Q2.14), [15:0] = W_re (Q2.14)
    output logic        valid_o,
    output logic [65:0] a_out, // [65:33] = im (Q19.14), [32:0] = re (Q19.14)
    output logic [65:0] b_out  // [65:33] = im (Q19.14), [32:0] = re (Q19.14)
);

    localparam int MUL_LATENCY_CYCLES = 4;

    logic        [31:0] a_aligned;
    logic               a_aligned_vld;
    logic signed [31:0] bw_re;
    logic signed [31:0] bw_im;

    logic signed [15:0] a_re_aligned;
    logic signed [15:0] a_im_aligned;

    logic signed [32:0] a_re_q19_14;
    logic signed [32:0] a_im_q19_14;
    logic signed [32:0] bw_re_q19_14;
    logic signed [32:0] bw_im_q19_14;

    logic signed [32:0] a_out_re_q19_14;
    logic signed [32:0] a_out_im_q19_14;
    logic signed [32:0] b_out_re_q19_14;
    logic signed [32:0] b_out_im_q19_14;
    logic        [65:0] a_out_comb;
    logic        [65:0] b_out_comb;

    function automatic logic signed [32:0] q16_0_to_q19_14(
        input logic signed [15:0] value_in
    );
        begin
            q16_0_to_q19_14 = $signed({{17{value_in[15]}}, value_in}) <<< 14;
        end
    endfunction

    shift_register_with_valid #(
        .WIDTH(32),
        .DEPTH(MUL_LATENCY_CYCLES)
    ) u_a_delay (
        .clk     (clk),
        .rst     (rst),
        .in_vld  (valid_i),
        .in_data (a),
        .out_vld (a_aligned_vld),
        .out_data(a_aligned)
    );

    complex_mul_3dsp u_complex_mul_3dsp (
        .clk   (clk),
        .rst   (rst),
        .x     (b),
        .y     (W),
        .out_re(bw_re),
        .out_im(bw_im)
    );

    assign a_re_aligned = $signed(a_aligned[15:0]);
    assign a_im_aligned = $signed(a_aligned[31:16]);

    assign a_re_q19_14 = q16_0_to_q19_14(a_re_aligned);
    assign a_im_q19_14 = q16_0_to_q19_14(a_im_aligned);
    assign bw_re_q19_14 = $signed({bw_re[31], bw_re});
    assign bw_im_q19_14 = $signed({bw_im[31], bw_im});

    assign a_out_re_q19_14 = a_re_q19_14 + bw_re_q19_14;
    assign a_out_im_q19_14 = a_im_q19_14 + bw_im_q19_14;
    assign b_out_re_q19_14 = a_re_q19_14 - bw_re_q19_14;
    assign b_out_im_q19_14 = a_im_q19_14 - bw_im_q19_14;

    assign a_out_comb = {a_out_im_q19_14, a_out_re_q19_14};
    assign b_out_comb = {b_out_im_q19_14, b_out_re_q19_14};

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_o <= 1'b0;
            a_out   <= '0;
            b_out   <= '0;
        end else begin
            valid_o <= a_aligned_vld;

            if (a_aligned_vld) begin
                a_out <= a_out_comb;
                b_out <= b_out_comb;
            end
        end
    end

endmodule
