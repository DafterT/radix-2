`timescale 1ns/1ps

import radix2_types_pkg::*;

module complex_round_clip_q22_23_to_q16_0 (
    input  logic signed [44:0] re_i,
    input  logic signed [44:0] im_i,
    output complex16_t         o_data
);

    logic signed [21:0] re_q22_0;
    logic signed [21:0] im_q22_0;
    complex16_comp_t    re_q16_0;
    complex16_comp_t    im_q16_0;

    convergent_rounding #(
        .IWID(45),
        .OWID(22)
    ) u_round_re (
        .i_data(re_i),
        .o_data(re_q22_0)
    );

    convergent_rounding #(
        .IWID(45),
        .OWID(22)
    ) u_round_im (
        .i_data(im_i),
        .o_data(im_q22_0)
    );

    symmetric_clip #(
        .IWID(22),
        .OWID(16)
    ) u_clip_re (
        .i_data(re_q22_0),
        .o_data(re_q16_0)
    );

    symmetric_clip #(
        .IWID(22),
        .OWID(16)
    ) u_clip_im (
        .i_data(im_q22_0),
        .o_data(im_q16_0)
    );

    assign o_data = radix2_types_pkg::comp_t_to_complex16(re_q16_0, im_q16_0);

endmodule
