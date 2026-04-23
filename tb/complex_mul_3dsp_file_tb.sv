`timescale 1ns/1ps

import radix2_types_pkg::*;

module complex_mul_3dsp_file_tb #(
    parameter int RESET_CYCLES = 4,
    parameter int CLK_PERIOD_NS = 10
);
    localparam int HALF_CLK_PERIOD_NS = CLK_PERIOD_NS / 2;
    localparam int OUTPUT_OFFSET_CYCLES = 4;

    import "DPI-C" function void complex_mul_3dsp_dpi_model(
        input int x_re,
        input int x_im,
        input int y_re,
        input int y_im,
        output longint out_re,
        output longint out_im
    );

    typedef struct {
        int id;
        complex16_t x;
        complex16_t y;
    } test_vec_t;

    logic clk;
    logic rst;

    complex16_t x;
    complex16_t y;
    complex16_t x_src;
    complex16_t y_src;
    complex33_t out;

    test_vec_t exp_queue[$];

    integer file_desc;
    integer vectors_count;
    integer fails_count;

    bit drive_done;
    bit check_done;

    string input_file;
    string dumpfile;

    function automatic test_vec_t make_test_vec(
        input int vec_id,
        input logic [31:0] x_raw,
        input logic [31:0] y_raw
    );
        test_vec_t vec;
        begin
            vec.id = vec_id;
            vec.x = radix2_types_pkg::bits_to_complex16(x_raw);
            vec.y = radix2_types_pkg::bits_to_complex16(y_raw);
            make_test_vec = vec;
        end
    endfunction

    function automatic test_vec_t zero_test_vec();
        test_vec_t vec;
        begin
            vec.id = 0;
            vec.x = '0;
            vec.y = '0;
            zero_test_vec = vec;
        end
    endfunction

    function automatic complex33_t calc_expected_out(input test_vec_t vec);
        /* verilator lint_off UNUSEDSIGNAL */
        longint signed model_re;
        longint signed model_im;
        /* verilator lint_on UNUSEDSIGNAL */
        complex33_comp_t expected_re;
        complex33_comp_t expected_im;
        begin
            complex_mul_3dsp_dpi_model(
                int'($signed(vec.x.re)),
                int'($signed(vec.x.im)),
                int'($signed(vec.y.re)),
                int'($signed(vec.y.im)),
                model_re,
                model_im
            );

            expected_re = complex33_comp_t'(model_re);
            expected_im = complex33_comp_t'(model_im);

            calc_expected_out = radix2_types_pkg::comp_t_to_complex33(
                expected_re,
                expected_im
            );
        end
    endfunction

    task automatic read_next_vector(
        input int next_id,
        output bit valid,
        output test_vec_t vec
    );
        logic [31:0] x_raw;
        logic [31:0] y_raw;
        int scan_status;
        begin
            scan_status = $fscanf(file_desc, "%h %h\n", x_raw, y_raw);
            valid = (scan_status == 2);
            vec = valid ? make_test_vec(next_id, x_raw, y_raw) : zero_test_vec();
        end
    endtask

    task automatic drive_vector(input test_vec_t vec);
        begin
            x_src = vec.x;
            y_src = vec.y;
        end
    endtask

    task automatic drive_zero_vector();
        begin
            x_src = '0;
            y_src = '0;
        end
    endtask

    function automatic void report_pass(
        input complex33_t out_in
    );
        begin
            $display(
                "PASS OUT=(%0d,%0d)",
                longint'($signed(out_in.re)),
                longint'($signed(out_in.im))
            );
        end
    endfunction

    function automatic void report_fail(
        input test_vec_t vec,
        input complex33_t got_out,
        input complex33_t exp_out
    );
        begin
            $display(
                "FAIL vec=%0d: X=(%0d,%0d) Y=(%0d,%0d) got=(%0d,%0d) exp=(%0d,%0d)",
                vec.id,
                int'($signed(vec.x.re)),
                int'($signed(vec.x.im)),
                int'($signed(vec.y.re)),
                int'($signed(vec.y.im)),
                longint'($signed(got_out.re)),
                longint'($signed(got_out.im)),
                longint'($signed(exp_out.re)),
                longint'($signed(exp_out.im))
            );
        end
    endfunction

    task automatic drive_task();
        bit valid;
        test_vec_t vec;
        begin
            forever begin
                read_next_vector(vectors_count + 1, valid, vec);

                @(posedge clk);

                if (!valid)
                    break;

                drive_vector(vec);
                exp_queue.push_back(vec);
                vectors_count = vec.id;
            end

            drive_done = 1'b1;

            forever begin
                @(posedge clk);
                drive_zero_vector();
                if (check_done)
                    return;
            end
        end
    endtask

    task automatic check_task();
        test_vec_t vec;
        complex33_t expected_out;
        begin
            wait ((exp_queue.size() != 0) || drive_done);

            repeat (OUTPUT_OFFSET_CYCLES) @(posedge clk);

            forever begin
                @(posedge clk);

                if (exp_queue.size() != 0) begin
                    vec = exp_queue.pop_front();
                    expected_out = calc_expected_out(vec);

                    if (out !== expected_out) begin
                        fails_count = fails_count + 1;
                        report_fail(vec, out, expected_out);
                    end else begin
                        report_pass(out);
                    end
                end else if (drive_done) begin
                    check_done = 1'b1;
                    return;
                end
            end
        end
    endtask

    complex_mul_3dsp dut (
        .clk(clk),
        .rst(rst),
        .x  (x),
        .y  (y),
        .out(out)
    );

    initial begin
        clk = 1'b0;
        forever begin
            #(HALF_CLK_PERIOD_NS)
            clk = ~clk;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            x <= '0;
            y <= '0;
        end else begin
            x <= x_src;
            y <= y_src;
        end
    end

    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "../build/complex_mul_3dsp_file_tb.vcd";

        if (!$value$plusargs("infile=%s", input_file))
            input_file = "../input/input_complex_vectors.txt";

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, complex_mul_3dsp_file_tb);
        end

        rst = 1'b1;
        x = '0;
        y = '0;
        x_src = '0;
        y_src = '0;
        vectors_count = 0;
        fails_count = 0;
        drive_done = 1'b0;
        check_done = 1'b0;

        file_desc = $fopen(input_file, "r");
        if (file_desc == 0)
            $fatal(1, "Cannot open input file: %0s", input_file);

        $display("[%0t] Mode: drive_style=posedge_ff output_offset_cycles=%0d", $time, OUTPUT_OFFSET_CYCLES);

        repeat (RESET_CYCLES) @(posedge clk);
        rst = 1'b0;

        fork
            drive_task();
            check_task();
        join

        $fclose(file_desc);

        $display("DONE: vectors=%0d fails=%0d", vectors_count, fails_count);

        if (fails_count != 0)
            $fatal(1, "complex_mul_3dsp_file_tb: FAILED");

        $finish;
    end

endmodule
