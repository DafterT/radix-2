`timescale 1ns/1ps

import radix2_types_pkg::*;

module radix2_butterfly (
    input  logic       clk,
    input  logic       rst,
    input  logic       valid_i,
    input  complex16_t a,       // Q16.0
    input  complex16_t b,       // Q16.0
    input  complex16_t W,       // Q2.14
    output logic       valid_o,
    output complex34_t a_out,   // Q20.14
    output complex34_t b_out    // Q20.14
);

    localparam int MUL_LATENCY_CYCLES = 4;
    localparam int A_WIDTH            = $bits(complex16_t);

    complex16_t         a_aligned;
    logic               a_aligned_vld;
    complex33_t         bw;
    complex34_t         a_out_comb;
    complex34_t         b_out_comb;

    function automatic complex34_comp_t q16_0_to_q20_14(
        input complex16_comp_t value_in
    );
        begin
            q16_0_to_q20_14 = $signed({{18{value_in[15]}}, value_in}) <<< 14;
        end
    endfunction

    function automatic complex34_comp_t q19_14_to_q20_14(
        input complex33_comp_t value_in
    );
        begin
            q19_14_to_q20_14 = $signed({value_in[32], value_in});
        end
    endfunction

    shift_register_with_valid #(
        .WIDTH(A_WIDTH),
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
        .clk(clk),
        .rst(rst),
        .x  (b),
        .y  (W),
        .out(bw)
    );

    assign a_out_comb.re = q16_0_to_q20_14(a_aligned.re) + q19_14_to_q20_14(bw.re);
    assign a_out_comb.im = q16_0_to_q20_14(a_aligned.im) + q19_14_to_q20_14(bw.im);
    assign b_out_comb.re = q16_0_to_q20_14(a_aligned.re) - q19_14_to_q20_14(bw.re);
    assign b_out_comb.im = q16_0_to_q20_14(a_aligned.im) - q19_14_to_q20_14(bw.im);

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
