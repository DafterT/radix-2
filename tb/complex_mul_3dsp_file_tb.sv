`timescale 1ns/1ps

module complex_mul_3dsp_file_tb #(
    parameter int RESET_CYCLES  = 4,
    parameter int CLK_PERIOD_NS = 10,
    parameter int OUTPUT_OFFSET_CYCLES = 4
);

    localparam int HALF_CLK_PERIOD_NS  = CLK_PERIOD_NS / 2;
    localparam int PIPE_LAST = OUTPUT_OFFSET_CYCLES - 1;

    logic clk;
    logic rst;

    logic signed [31:0] x;
    logic signed [31:0] y;
    logic signed [31:0] out_re;
    logic signed [31:0] out_im;

    integer file_desc;
    integer scan_status;
    integer vectors_count;
    integer fails_count;

    logic [31:0] x_raw;
    logic [31:0] y_raw;
    logic signed [31:0] x_vec;
    logic signed [31:0] y_vec;
    reg [1023:0] skipped_line;

    logic                   valid_pipe [0:PIPE_LAST];
    integer                 id_pipe    [0:PIPE_LAST];
    logic signed [31:0]     x_pipe     [0:PIPE_LAST];
    logic signed [31:0]     y_pipe     [0:PIPE_LAST];
    logic signed [31:0]     exp_re_pipe[0:PIPE_LAST];
    logic signed [31:0]     exp_im_pipe[0:PIPE_LAST];

    reg [1023:0] input_file;
    reg [1023:0] dumpfile;

    function automatic logic signed [31:0] calc_expected_re(
        input logic signed [31:0] x_in,
        input logic signed [31:0] y_in
    );
        logic signed [15:0] a_re, a_im, b_re, b_im;
        logic signed [31:0] p0, p1;
        begin
            a_im = $signed(x_in[31:16]);
            a_re = $signed(x_in[15:0]);
            b_im = $signed(y_in[31:16]);
            b_re = $signed(y_in[15:0]);

            p0 = a_re * b_re;
            p1 = a_im * b_im;

            calc_expected_re = $signed(p0) - $signed(p1);
        end
    endfunction

    function automatic logic signed [31:0] calc_expected_im(
        input logic signed [31:0] x_in,
        input logic signed [31:0] y_in
    );
        logic signed [15:0] a_re, a_im, b_re, b_im;
        logic signed [31:0] p0, p1;
        begin
            a_im = $signed(x_in[31:16]);
            a_re = $signed(x_in[15:0]);
            b_im = $signed(y_in[31:16]);
            b_re = $signed(y_in[15:0]);

            p0 = a_re * b_im;
            p1 = a_im * b_re;

            calc_expected_im = $signed(p0) + $signed(p1);
        end
    endfunction

    task automatic drive_vector(
        input logic signed [31:0] x_in,
        input logic signed [31:0] y_in
    );
        begin
            x = x_in;
            y = y_in;
        end
    endtask

    complex_mul_3dsp dut (
        .clk   (clk),
        .rst   (rst),
        .x     (x),
        .y     (y),
        .out_re(out_re),
        .out_im(out_im)
    );

    initial clk = 1'b0;
    always #(HALF_CLK_PERIOD_NS) clk = ~clk;

    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "tb/build/complex_mul_3dsp_file_tb.vcd";

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, complex_mul_3dsp_file_tb);
            $display("[%0t] VCD enabled: %0s", $time, dumpfile);
        end
    end

    initial begin
        bit got_vector;
        bit eof_reached;
        bit done;
        integer flush_left;
        int i;

        rst         = 1'b1;
        x           = '0;
        y           = '0;
        vectors_count = 0;
        fails_count   = 0;
        eof_reached   = 1'b0;
        done          = 1'b0;
        flush_left    = OUTPUT_OFFSET_CYCLES;

        for (i = 0; i < OUTPUT_OFFSET_CYCLES; i++) begin
            valid_pipe[i]  = 1'b0;
            id_pipe[i]     = 0;
            x_pipe[i]      = '0;
            y_pipe[i]      = '0;
            exp_re_pipe[i] = '0;
            exp_im_pipe[i] = '0;
        end

        if (!$value$plusargs("infile=%s", input_file))
            input_file = "tb/input_complex_vectors.txt";

        file_desc = $fopen(input_file, "r");
        if (file_desc == 0) begin
            $fatal(1, "Cannot open input file: %0s", input_file);
        end

        $display("[%0t] Reading vectors from: %0s", $time, input_file);
        $display("[%0t] File format per line: X Y (hex, packed as {imag[31:16], real[15:0]})", $time);
        $display("[%0t] Output offset: %0d cycles", $time, OUTPUT_OFFSET_CYCLES);
        $display("[%0t] Drive mode: one new vector each clock cycle", $time);

        repeat (RESET_CYCLES) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        while (!done) begin
            @(negedge clk);

            if (valid_pipe[PIPE_LAST]) begin
                if ((out_re !== exp_re_pipe[PIPE_LAST]) || (out_im !== exp_im_pipe[PIPE_LAST])) begin
                    fails_count = fails_count + 1;
                    $display(
                        "FAIL vec=%0d: x=0x%08h y=0x%08h -> got(re=%0d im=%0d) exp(re=%0d im=%0d)",
                        id_pipe[PIPE_LAST],
                        x_pipe[PIPE_LAST],
                        y_pipe[PIPE_LAST],
                        out_re,
                        out_im,
                        exp_re_pipe[PIPE_LAST],
                        exp_im_pipe[PIPE_LAST]
                    );
                end else begin
                    $display(
                        "PASS vec=%0d: x=0x%08h y=0x%08h -> re=%0d im=%0d",
                        id_pipe[PIPE_LAST],
                        x_pipe[PIPE_LAST],
                        y_pipe[PIPE_LAST],
                        out_re,
                        out_im
                    );
                end
            end

            for (i = PIPE_LAST; i > 0; i--) begin
                valid_pipe[i]  = valid_pipe[i-1];
                id_pipe[i]     = id_pipe[i-1];
                x_pipe[i]      = x_pipe[i-1];
                y_pipe[i]      = y_pipe[i-1];
                exp_re_pipe[i] = exp_re_pipe[i-1];
                exp_im_pipe[i] = exp_im_pipe[i-1];
            end

            valid_pipe[0]  = 1'b0;
            id_pipe[0]     = 0;
            x_pipe[0]      = '0;
            y_pipe[0]      = '0;
            exp_re_pipe[0] = '0;
            exp_im_pipe[0] = '0;

            if (!eof_reached) begin
                got_vector = 1'b0;
                while (!got_vector && !$feof(file_desc)) begin
                    scan_status = $fscanf(file_desc, "%h %h\n", x_raw, y_raw);
                    if (scan_status == 2) begin
                        got_vector = 1'b1;
                    end else if (!$feof(file_desc)) begin
                        scan_status = $fgets(skipped_line, file_desc);
                    end
                end

                if (got_vector) begin
                    x_vec = $signed(x_raw);
                    y_vec = $signed(y_raw);
                    vectors_count = vectors_count + 1;

                    drive_vector(x_vec, y_vec);

                    valid_pipe[0]  = 1'b1;
                    id_pipe[0]     = vectors_count;
                    x_pipe[0]      = x_vec;
                    y_pipe[0]      = y_vec;
                    exp_re_pipe[0] = calc_expected_re(x_vec, y_vec);
                    exp_im_pipe[0] = calc_expected_im(x_vec, y_vec);
                end else begin
                    eof_reached = 1'b1;
                    drive_vector('0, '0);
                    flush_left = flush_left - 1;
                    if (flush_left == 0)
                        done = 1'b1;
                end
            end else begin
                drive_vector('0, '0);
                flush_left = flush_left - 1;
                if (flush_left == 0)
                    done = 1'b1;
            end
        end

        $fclose(file_desc);

        $display("DONE: vectors=%0d fails=%0d", vectors_count, fails_count);
        if (fails_count != 0) begin
            $fatal(1, "complex_mul_3dsp_file_tb: FAILED");
        end
        $finish;
    end

endmodule
