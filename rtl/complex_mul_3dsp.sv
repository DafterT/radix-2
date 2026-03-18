`timescale 1ns/1ps

module complex_mul_3dsp (
    input  logic                 clk,
    input  logic                 rst,
    input  logic        [31:0]   x,       // [31:16] = a_im (Q16.0), [15:0] = a_re (Q16.0)
    input  logic        [31:0]   y,       // [31:16] = b_im (Q2.14), [15:0] = b_re (Q2.14)
    output logic signed [31:0]   out_re,  // Q18.14
    output logic signed [31:0]   out_im   // Q18.14
);

    logic signed [15:0] x_re, x_im;
    logic signed [15:0] y_re, y_im;

    logic signed [47:0] m0;
    logic signed [47:0] m1;
    logic signed [47:0] m2;

    function automatic logic signed [29:0] sx30(input logic signed [15:0] v);
        sx30 = $signed({{14{v[15]}}, v});
    endfunction

    function automatic logic signed [26:0] sx27(input logic signed [15:0] v);
        sx27 = $signed({{11{v[15]}}, v});
    endfunction

    function automatic logic signed [17:0] sx18(input logic signed [15:0] v);
        sx18 = $signed({{2{v[15]}}, v});
    endfunction

    assign x_im = $signed(x[31:16]);
    assign x_re = $signed(x[15:0]);
    assign y_im = $signed(y[31:16]);
    assign y_re = $signed(y[15:0]);

    DSP48E2_like #(
        .PREADD_SUB (1'b0),
        .POSTADD_EN (1'b0),
        .POSTADD_SUB(1'b0)
    ) dsp0 (
        .clk(clk),
        .rst(rst),
        .A  (sx30(y_im)), // To pread  b
        .D  (sx27(y_re)), // To pread  B
        .B  (sx18(x_re)), // Dualreg   A
        .C  ('0),
        .Y  (m0)
    );

    DSP48E2_like #(
        .PREADD_SUB (1'b0),
        .POSTADD_EN (1'b1),
        .POSTADD_SUB(1'b1)
    ) dsp1 (
        .clk(clk),
        .rst(rst),
        .A  (sx30(x_re)),   // To pread  A
        .D  (sx27(x_im)),   // To pread  a
        .B  (sx18(y_im)),  // Dualreg    b
        .C  (m0),          // To Sum
        .Y  (m1)
    );

    DSP48E2_like #(
        .PREADD_SUB (1'b1),
        .POSTADD_EN (1'b1),
        .POSTADD_SUB(1'b0)
    ) dsp2 (
        .clk(clk),
        .rst(rst),
        .A  (sx30(x_re)),  // To pread  A
        .D  (sx27(x_im)),  // To pread  a
        .B  (sx18(y_re)),  // Dualreg   B
        .C  (m0),          // To Sum
        .Y  (m2)
    );

    assign out_re = $signed(m1[31:0]);
    assign out_im = $signed(m2[31:0]);

endmodule
