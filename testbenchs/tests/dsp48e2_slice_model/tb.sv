`timescale 1ns/1ps

module dsp48e2_slice_model_dpi_tb #(
    parameter int PREADD_SUB = 0,
    parameter int POSTADD_EN = 0,
    parameter int POSTADD_SUB = 0
);
    parameter int RESET_CYCLES = 4;
    parameter int CLK_PERIOD_NS = 10;
    localparam int HALF_CLK_PERIOD_NS = CLK_PERIOD_NS / 2;

    import "DPI-C" function longint dsp48e2_slice_model_dpi_model(
        input bit preadd_sub,
        input bit postadd_en,
        input bit postadd_sub,
        input int a,
        input int d,
        input int b,
        input longint c
    );

    typedef struct {
        int id;
        logic signed [29:0] a;
        logic signed [26:0] d;
        logic signed [17:0] b;
        logic signed [47:0] c;
    } test_vec_t;

    localparam int OUTPUT_OFFSET_CYCLES = (POSTADD_EN != 0) ? 4 : 3;

    logic clk;
    logic rst;

    logic signed [29:0] A;
    logic signed [26:0] D;
    logic signed [17:0] B;
    logic signed [47:0] C;
    logic signed [47:0] Y;

    logic signed [29:0] a_src;
    logic signed [26:0] d_src;
    logic signed [17:0] b_src;
    logic signed [47:0] c_src_next;
    logic signed [47:0] c_src;
    logic signed [47:0] c_pipe0_q;
    logic signed [47:0] c_pipe1_q;

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
        input integer a_raw,
        input integer d_raw,
        input integer b_raw,
        input longint signed c_raw
    );
        test_vec_t vec;
        begin
            vec.id = vec_id;
            vec.a  = $signed(a_raw[29:0]);
            vec.d  = $signed(d_raw[26:0]);
            vec.b  = $signed(b_raw[17:0]);
            vec.c  = $signed(c_raw[47:0]);
            make_test_vec = vec;
        end
    endfunction

    function automatic test_vec_t zero_test_vec();
        test_vec_t vec;
        begin
            vec.id = 0;
            vec.a  = '0;
            vec.d  = '0;
            vec.b  = '0;
            vec.c  = '0;
            zero_test_vec = vec;
        end
    endfunction

    function automatic logic signed [47:0] calc_expected_y(input test_vec_t vec);
        longint signed model_y;
        begin
            model_y = dsp48e2_slice_model_dpi_model(
                (PREADD_SUB != 0),
                (POSTADD_EN != 0),
                (POSTADD_SUB != 0),
                int'($signed(vec.a)),
                int'($signed(vec.d)),
                int'($signed(vec.b)),
                longint'($signed(vec.c))
            );
            calc_expected_y = $signed(model_y[47:0]);
        end
    endfunction

    task automatic read_next_vector(
        input int next_id,
        output bit valid,
        output test_vec_t vec
    );
        int a_raw;
        int d_raw;
        int b_raw;
        longint signed c_raw;
        int scan_status;
        begin
            scan_status = $fscanf(file_desc, "%d %d %d %d\n", a_raw, d_raw, b_raw, c_raw);
            valid = (scan_status == 4);
            vec = valid ? make_test_vec(next_id, a_raw, d_raw, b_raw, c_raw) : zero_test_vec();
        end
    endtask

    task automatic drive_vector(input test_vec_t vec);
        begin
            a_src     = vec.a;
            d_src     = vec.d;
            b_src     = vec.b;
            c_src_next = vec.c;
        end
    endtask

    task automatic drive_zero_vector();
        begin
            a_src      = '0;
            d_src      = '0;
            b_src      = '0;
            c_src_next = '0;
        end
    endtask

    function automatic void report_pass(
        input test_vec_t vec,
        input logic signed [47:0] y_in
    );
        begin
            $display("PASS vec=%0d: Y=%0d", vec.id, y_in);
        end
    endfunction

    function automatic void report_fail(
        input test_vec_t vec,
        input logic signed [47:0] got_y,
        input logic signed [47:0] exp_y
    );
        begin
            $display(
                "FAIL vec=%0d: A=%0d D=%0d B=%0d C=%0d got Y=%0d exp Y=%0d",
                vec.id,
                vec.a,
                vec.d,
                vec.b,
                vec.c,
                got_y,
                exp_y
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
        logic signed [47:0] expected_y;
        begin
            wait ((exp_queue.size() != 0) || drive_done);

            repeat (OUTPUT_OFFSET_CYCLES) @(posedge clk);

            forever begin
                @(posedge clk);

                if (exp_queue.size() != 0) begin
                    vec = exp_queue.pop_front();
                    expected_y = calc_expected_y(vec);

                    if (Y !== expected_y) begin
                        fails_count = fails_count + 1;
                        report_fail(vec, Y, expected_y);
                    end else begin
                        report_pass(vec, Y);
                    end
                end else if (drive_done) begin
                    check_done = 1'b1;
                    return;
                end
            end
        end
    endtask

    dsp48e2_slice_model #(
        .PREADD_SUB (PREADD_SUB != 0),
        .POSTADD_EN (POSTADD_EN != 0),
        .POSTADD_SUB(POSTADD_SUB != 0)
    ) dut (
        .clk(clk),
        .rst(rst),
        .A  (A),
        .D  (D),
        .B  (B),
        .C  (C),
        .Y  (Y)
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
            A <= '0;
        end else begin
            A <= a_src;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            D <= '0;
        end else begin
            D <= d_src;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            B <= '0;
        end else begin
            B <= b_src;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            c_src     <= '0;
            c_pipe0_q <= '0;
            c_pipe1_q <= '0;
            C         <= '0;
        end else begin
            c_src     <= c_src_next;
            c_pipe0_q <= c_src;
            c_pipe1_q <= c_pipe0_q;
            C         <= c_pipe1_q;
        end
    end

    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "build/waves/dsp48e2_slice_model.vcd";

        if (!$value$plusargs("infile=%s", input_file))
            input_file = "tests/dsp48e2_slice_model/input.txt";

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, dsp48e2_slice_model_dpi_tb);
        end

        rst = 1'b1;
        A = '0;
        D = '0;
        B = '0;
        C = '0;
        a_src = '0;
        d_src = '0;
        b_src = '0;
        c_src_next = '0;
        c_src = '0;
        c_pipe0_q = '0;
        c_pipe1_q = '0;
        vectors_count = 0;
        fails_count = 0;
        drive_done = 1'b0;
        check_done = 1'b0;

        file_desc = $fopen(input_file, "r");
        if (file_desc == 0)
            $fatal(1, "Cannot open input file: %0s", input_file);

        $display("[%0t] Mode: preadd_sub=%0d postadd_en=%0d postadd_sub=%0d", $time, PREADD_SUB, POSTADD_EN, POSTADD_SUB);

        repeat (RESET_CYCLES) @(posedge clk);
        rst = 1'b0;

        fork
            drive_task();
            check_task();
        join

        $fclose(file_desc);

        $display("DONE: vectors=%0d fails=%0d", vectors_count, fails_count);

        if (fails_count != 0)
            $fatal(1, "dsp48e2_slice_model_dpi_tb: FAILED");

        $finish;
    end

endmodule
