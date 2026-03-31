`timescale 1ns/1ps

package radix2_types_pkg;

    typedef logic signed [15:0] complex16_comp_t;
    typedef logic signed [32:0] complex33_comp_t;
    typedef logic signed [33:0] complex34_comp_t;

    typedef struct packed {
        complex16_comp_t im;
        complex16_comp_t re;
    } complex16_t;

    typedef struct packed {
        complex33_comp_t im;
        complex33_comp_t re;
    } complex33_t;

    typedef struct packed {
        complex34_comp_t im;
        complex34_comp_t re;
    } complex34_t;

    function automatic complex16_t bits_to_complex16(input logic [31:0] value_in);
        begin
            bits_to_complex16 = complex16_t'(value_in);
        end
    endfunction

    function automatic complex33_t bits_to_complex33(input logic [65:0] value_in);
        begin
            bits_to_complex33 = complex33_t'(value_in);
        end
    endfunction

    function automatic complex34_t bits_to_complex34(input logic [67:0] value_in);
        begin
            bits_to_complex34 = complex34_t'(value_in);
        end
    endfunction

    function automatic complex16_t comp_t_to_complex16(
        input complex16_comp_t re_in,
        input complex16_comp_t im_in
    );
        complex16_t value_out;
        begin
            value_out.re = re_in;
            value_out.im = im_in;
            comp_t_to_complex16 = value_out;
        end
    endfunction

    function automatic complex33_t comp_t_to_complex33(
        input complex33_comp_t re_in,
        input complex33_comp_t im_in
    );
        complex33_t value_out;
        begin
            value_out.re = re_in;
            value_out.im = im_in;
            comp_t_to_complex33 = value_out;
        end
    endfunction

    function automatic complex34_t comp_t_to_complex34(
        input complex34_comp_t re_in,
        input complex34_comp_t im_in
    );
        complex34_t value_out;
        begin
            value_out.re = re_in;
            value_out.im = im_in;
            comp_t_to_complex34 = value_out;
        end
    endfunction

endpackage
