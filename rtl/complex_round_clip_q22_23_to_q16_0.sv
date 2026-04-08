`timescale 1ns/1ps

import radix2_types_pkg::*;

module complex_round_clip_q22_23_to_q16_0 (
    input  logic               clk,
    input  logic               rst,
    input  logic signed [44:0] re_i,
    input  logic signed [44:0] im_i,
    output complex16_t         o_data
);

    logic signed [21:0] re_q22_0_round;
    logic signed [21:0] im_q22_0_round;
    logic signed [21:0] re_q22_0_reg;
    logic signed [21:0] im_q22_0_reg;
    complex16_comp_t    re_q16_0;
    complex16_comp_t    im_q16_0;

    convergent_rounding #(
        .IWID(45),
        .OWID(22)
    ) u_round_re (
        .i_data(re_i),
        .o_data(re_q22_0_round)
    );

    convergent_rounding #(
        .IWID(45),
        .OWID(22)
    ) u_round_im (
        .i_data(im_i),
        .o_data(im_q22_0_round)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            re_q22_0_reg <= '0;
            im_q22_0_reg <= '0;
        end else begin
            re_q22_0_reg <= re_q22_0_round;
            im_q22_0_reg <= im_q22_0_round;
        end
    end

    symmetric_clip #(
        .IWID(22),
        .OWID(16)
    ) u_clip_re (
        .i_data(re_q22_0_reg),
        .o_data(re_q16_0)
    );

    symmetric_clip #(
        .IWID(22),
        .OWID(16)
    ) u_clip_im (
        .i_data(im_q22_0_reg),
        .o_data(im_q16_0)
    );

    assign o_data = radix2_types_pkg::comp_t_to_complex16(re_q16_0, im_q16_0);

endmodule
