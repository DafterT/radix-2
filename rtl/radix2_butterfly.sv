`timescale 1ns/1ps

import complex_fixed_pkg::*;

module radix2_butterfly (
    input  logic       clk,
    input  logic       rst,
    input  logic       valid_i,
    input  complex16_t a,       // Q16.0
    input  complex16_t b,       // Q16.0
    input  complex16_t W,       // Q2.14
    output logic       valid_o,
    output complex16_t a_out,   // Q16.0
    output complex16_t b_out    // Q16.0
);

    localparam int MUL_LATENCY_CYCLES     = 4;
    localparam int A_WIDTH                = $bits(complex16_t);
    localparam int OUTPUT_PIPELINE_STAGES = 4;

    // 1 / SQRT(2) в формате Q1.17
    localparam real INV_SQRT2_REAL = 1.0 / $sqrt(2.0);
    localparam logic signed [17:0] INV_SQRT2_Q1_17 = $rtoi(INV_SQRT2_REAL * (1 << 17));

    // Выравнивание входа a по задержке
    complex16_t         a_aligned;
    logic               a_aligned_vld;
    complex33_t         bw;
    // Приведение форматов перед DSP
    complex34_comp_t    a_re_q20_14;
    complex34_comp_t    a_im_q20_14;
    complex34_comp_t    bw_re_q20_14;
    complex34_comp_t    bw_im_q20_14;
    logic signed [26:0] a_re_dsp_in;
    logic signed [26:0] a_im_dsp_in;
    logic signed [26:0] bw_re_dsp_in;
    logic signed [26:0] bw_im_dsp_in;
    logic signed [29:0] bw_re_dsp_a;
    logic signed [29:0] bw_im_dsp_a;
    // Сырые выходы DSP и суженные значения Q22.23
    logic signed [47:0] a_out_re_dsp_raw;
    logic signed [47:0] a_out_im_dsp_raw;
    logic signed [47:0] b_out_re_dsp_raw;
    logic signed [47:0] b_out_im_dsp_raw;
    logic signed [44:0] a_out_re_q22_23;
    logic signed [44:0] a_out_im_q22_23;
    logic signed [44:0] b_out_re_q22_23;
    logic signed [44:0] b_out_im_q22_23;
    // Постобработка до Q16.0
    complex16_t         a_out_q16_0;
    complex16_t         b_out_q16_0;
    // Пайплайн valid
    logic [OUTPUT_PIPELINE_STAGES-1:0] valid_pipe;

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

    function automatic logic signed [26:0] q20_14_to_dsp_preadder(
        input complex34_comp_t value_in
    );
        begin
            // Q20.14 -> оставляем биты [33:8], получаем Q20.6
            // и расширяем знак до 27 бит для preadder.
            q20_14_to_dsp_preadder = $signed({value_in[33], value_in[33:8]});
        end
    endfunction

    function automatic logic signed [29:0] sign_extend_27_to_30(
        input logic signed [26:0] value_in
    );
        begin
            sign_extend_27_to_30 = $signed({{3{value_in[26]}}, value_in});
        end
    endfunction

    delay_line_with_valid #(
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

    assign a_re_q20_14  = q16_0_to_q20_14(a_aligned.re);
    assign a_im_q20_14  = q16_0_to_q20_14(a_aligned.im);
    assign bw_re_q20_14 = q19_14_to_q20_14(bw.re);
    assign bw_im_q20_14 = q19_14_to_q20_14(bw.im);

    assign a_re_dsp_in  = q20_14_to_dsp_preadder(a_re_q20_14);
    assign a_im_dsp_in  = q20_14_to_dsp_preadder(a_im_q20_14);
    assign bw_re_dsp_in = q20_14_to_dsp_preadder(bw_re_q20_14);
    assign bw_im_dsp_in = q20_14_to_dsp_preadder(bw_im_q20_14);
    
    assign bw_re_dsp_a  = sign_extend_27_to_30(bw_re_dsp_in);
    assign bw_im_dsp_a  = sign_extend_27_to_30(bw_im_dsp_in);

    dsp48e2_slice_model #(
        .PREADD_SUB (1'b0),
        .POSTADD_EN (1'b0),
        .POSTADD_SUB(1'b0)
    ) u_a_out_re_dsp (
        .clk(clk),
        .rst(rst),
        .A  (bw_re_dsp_a),
        .D  (a_re_dsp_in),
        .B  (INV_SQRT2_Q1_17),
        .C  (48'sd0),
        .Y  (a_out_re_dsp_raw)
    );

    dsp48e2_slice_model #(
        .PREADD_SUB (1'b0),
        .POSTADD_EN (1'b0),
        .POSTADD_SUB(1'b0)
    ) u_a_out_im_dsp (
        .clk(clk),
        .rst(rst),
        .A  (bw_im_dsp_a),
        .D  (a_im_dsp_in),
        .B  (INV_SQRT2_Q1_17),
        .C  (48'sd0),
        .Y  (a_out_im_dsp_raw)
    );

    dsp48e2_slice_model #(
        .PREADD_SUB (1'b1),
        .POSTADD_EN (1'b0),
        .POSTADD_SUB(1'b0)
    ) u_b_out_re_dsp (
        .clk(clk),
        .rst(rst),
        .A  (bw_re_dsp_a),
        .D  (a_re_dsp_in),
        .B  (INV_SQRT2_Q1_17),
        .C  (48'sd0),
        .Y  (b_out_re_dsp_raw)
    );

    dsp48e2_slice_model #(
        .PREADD_SUB (1'b1),
        .POSTADD_EN (1'b0),
        .POSTADD_SUB(1'b0)
    ) u_b_out_im_dsp (
        .clk(clk),
        .rst(rst),
        .A  (bw_im_dsp_a),
        .D  (a_im_dsp_in),
        .B  (INV_SQRT2_Q1_17),
        .C  (48'sd0),
        .Y  (b_out_im_dsp_raw)
    );

    assign a_out_re_q22_23 = $signed(a_out_re_dsp_raw[44:0]);
    assign a_out_im_q22_23 = $signed(a_out_im_dsp_raw[44:0]);
    assign b_out_re_q22_23 = $signed(b_out_re_dsp_raw[44:0]);
    assign b_out_im_q22_23 = $signed(b_out_im_dsp_raw[44:0]);

    complex_requantize_q22_23_to_q16_0 u_a_out_post (
        .clk (clk),
        .rst (rst),
        .re_i(a_out_re_q22_23),
        .im_i(a_out_im_q22_23),
        .o_data(a_out_q16_0)
    );

    complex_requantize_q22_23_to_q16_0 u_b_out_post (
        .clk (clk),
        .rst (rst),
        .re_i(b_out_re_q22_23),
        .im_i(b_out_im_q22_23),
        .o_data(b_out_q16_0)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_pipe <= '0;
            valid_o    <= 1'b0;
        end else begin
            valid_pipe[0] <= a_aligned_vld;
            for (int i = 1; i < OUTPUT_PIPELINE_STAGES; i++)
                valid_pipe[i] <= valid_pipe[i-1];

            valid_o <= valid_pipe[OUTPUT_PIPELINE_STAGES-1];
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            a_out <= '0;
            b_out <= '0;
        end else if (valid_pipe[OUTPUT_PIPELINE_STAGES-1]) begin
            a_out <= a_out_q16_0;
            b_out <= b_out_q16_0;
        end
    end

endmodule
