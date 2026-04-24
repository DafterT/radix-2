`timescale 1ns/1ps

import complex_fixed_pkg::*;

module complex_mul_3dsp (
    input  logic            clk,
    input  logic            rst,
    input  complex16_t      x,   // Q16.0
    input  complex16_t      y,   // Q2.14
    output complex33_t      out  // Q19.14
);

    localparam int X_COMP_W          = $bits(complex16_comp_t);
    localparam int Y_COMP_W          = $bits(complex16_comp_t);
    localparam int MUL_TERM_W        = X_COMP_W + Y_COMP_W;
    localparam int CMUL_SUM_GROWTH_W = 1;
    localparam int OUT_W             = MUL_TERM_W + CMUL_SUM_GROWTH_W;

    logic signed [47:0] m0;
    logic signed [47:0] m1;
    logic signed [47:0] m2;

    function automatic logic signed [29:0] sign_extend_to_30(input complex16_comp_t v);
        sign_extend_to_30 = $signed({{14{v[15]}}, v});
    endfunction

    function automatic logic signed [26:0] sign_extend_to_27(input complex16_comp_t v);
        sign_extend_to_27 = $signed({{11{v[15]}}, v});
    endfunction

    function automatic logic signed [17:0] sign_extend_to_18(input complex16_comp_t v);
        sign_extend_to_18 = $signed({{2{v[15]}}, v});
    endfunction

    dsp48e2_slice_model #(
        .PREADD_SUB (1'b0),
        .POSTADD_EN (1'b0),
        .POSTADD_SUB(1'b0)
    ) dsp1 (
        .clk(clk),
        .rst(rst),
        .A  (sign_extend_to_30(y.im)), // To pread  b
        .D  (sign_extend_to_27(y.re)), // To pread  B
        .B  (sign_extend_to_18(x.re)), // Dualreg   A
        .C  ('0),
        .Y  (m0)
    );

    dsp48e2_slice_model #(
        .PREADD_SUB (1'b0),
        .POSTADD_EN (1'b1),
        .POSTADD_SUB(1'b1)
    ) dsp2 (
        .clk(clk),
        .rst(rst),
        .A  (sign_extend_to_30(x.re)), // To pread  A
        .D  (sign_extend_to_27(x.im)), // To pread  a
        .B  (sign_extend_to_18(y.im)), // Dualreg   b
        .C  (m0),                      // To Sum
        .Y  (m1)
    );

    dsp48e2_slice_model #(
        .PREADD_SUB (1'b1),
        .POSTADD_EN (1'b1),
        .POSTADD_SUB(1'b0)
    ) dsp3 (
        .clk(clk),
        .rst(rst),
        .A  (sign_extend_to_30(x.re)), // To pread  A
        .D  (sign_extend_to_27(x.im)), // To pread  a
        .B  (sign_extend_to_18(y.re)), // Dualreg   B
        .C  (m0),                      // To Sum
        .Y  (m2)
    );

    assign out = complex_fixed_pkg::comp_t_to_complex33(
        $signed(m1[OUT_W-1:0]),
        $signed(m2[OUT_W-1:0])
    );

endmodule
