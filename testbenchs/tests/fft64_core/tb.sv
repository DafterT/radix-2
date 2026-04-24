`timescale 1ns/1ps

module fft64_core_dpi_tb;
    parameter int CLK_PERIOD_NS = 10;
    parameter int RESET_CYCLES = 4;

    localparam int FFT_N = 64;
    localparam int TDATA_W = 32;
    localparam int HALF_CLK_PERIOD_NS = CLK_PERIOD_NS / 2;
    localparam int WATCHDOG_CYCLES = 200000;
    localparam int DEFAULT_FRAMES = 32;
    localparam int DEFAULT_SEED = 1;
    localparam real DEFAULT_BACKOFF_DB = 12.0;

    import "DPI-C" function void fft64_core_dpi_generate_frame(
        input int seed,
        input int frame_index,
        input real backoff_db,
        output shortint re[],
        output shortint im[]
    );

    import "DPI-C" function void fft64_core_dpi_model_frame(
        input shortint in_re[],
        input shortint in_im[],
        output shortint out_re[],
        output shortint out_im[]
    );

    logic               clk;
    logic               rst;
    logic [TDATA_W-1:0] s_axis_tdata;
    logic               s_axis_tvalid;
    logic               s_axis_tready;
    logic [TDATA_W-1:0] m_axis_tdata;
    logic               m_axis_tvalid;
    logic               m_axis_tready;

    int exp_queue[$];

    int frames_limit;
    int seed;
    int frames_count;
    int fails_count;

    bit drive_done;
    bit check_done;

    real backoff_db;
    string dumpfile;

    function automatic logic [31:0] pack_sample(
        input shortint re_in,
        input shortint im_in
    );
        logic signed [15:0] re_bits;
        logic signed [15:0] im_bits;
        begin
            re_bits = re_in;
            im_bits = im_in;
            pack_sample = {im_bits, re_bits};
        end
    endfunction

    function automatic void report_pass(input int frame_id);
        begin
            $display("PASS frame=%0d", frame_id);
        end
    endfunction

    function automatic void report_fail(
        input int frame_id,
        input int bin_index,
        input shortint in_re,
        input shortint in_im,
        input logic [31:0] got_word,
        input shortint exp_re,
        input shortint exp_im
    );
        logic signed [15:0] got_re_bits;
        logic signed [15:0] got_im_bits;
        begin
            got_re_bits = got_word[15:0];
            got_im_bits = got_word[31:16];
            $display(
                "FAIL frame=%0d bin=%0d: in=(%0d,%0d) got=0x%08h (%0d,%0d) exp=(%0d,%0d)",
                frame_id,
                bin_index,
                in_re,
                in_im,
                got_word,
                got_re_bits,
                got_im_bits,
                exp_re,
                exp_im
            );
        end
    endfunction

    task automatic generate_frame(
        input int frame_id,
        output shortint frame_re[0:FFT_N-1],
        output shortint frame_im[0:FFT_N-1]
    );
        begin
            fft64_core_dpi_generate_frame(seed, frame_id, backoff_db, frame_re, frame_im);
        end
    endtask

    task automatic calc_expected_frame(
        input shortint in_re[0:FFT_N-1],
        input shortint in_im[0:FFT_N-1],
        output shortint out_re[0:FFT_N-1],
        output shortint out_im[0:FFT_N-1]
    );
        begin
            fft64_core_dpi_model_frame(in_re, in_im, out_re, out_im);
        end
    endtask

    task automatic drive_idle();
        begin
            s_axis_tvalid = 1'b0;
            s_axis_tdata = '0;
        end
    endtask

    task automatic drive_frame_task(
        input shortint frame_re[0:FFT_N-1],
        input shortint frame_im[0:FFT_N-1]
    );
        int sample_index;
        begin
            sample_index = 0;

            while (sample_index < FFT_N) begin
                s_axis_tvalid = 1'b1;
                s_axis_tdata = pack_sample(frame_re[sample_index], frame_im[sample_index]);

                @(posedge clk);

                if (s_axis_tready)
                    sample_index += 1;
            end

            drive_idle();
        end
    endtask

    task automatic drive_task();
        shortint frame_re[0:FFT_N-1];
        shortint frame_im[0:FFT_N-1];
        int frame_id;
        begin
            for (frame_id = 1; frame_id <= frames_limit; frame_id += 1) begin
                generate_frame(frame_id, frame_re, frame_im);
                exp_queue.push_back(frame_id);
                drive_frame_task(frame_re, frame_im);
                frames_count = frame_id;
            end

            drive_done = 1'b1;

            forever begin
                @(posedge clk);
                drive_idle();
                if (check_done)
                    return;
            end
        end
    endtask

    task automatic check_task();
        shortint input_re[0:FFT_N-1];
        shortint input_im[0:FFT_N-1];
        shortint expected_re[0:FFT_N-1];
        shortint expected_im[0:FFT_N-1];
        logic [31:0] got_words[0:FFT_N-1];
        logic [31:0] expected_word;
        bit frame_failed;
        int frame_id;
        int got_count;
        begin
            got_count = 0;

            wait ((exp_queue.size() != 0) || drive_done);

            forever begin
                @(posedge clk);

                if (m_axis_tvalid && m_axis_tready) begin
                    got_words[got_count] = m_axis_tdata;
                    got_count += 1;

                    if (got_count == FFT_N) begin
                        if (exp_queue.size() == 0)
                            $fatal(1, "radix2_fft64_dpi_tb: checker observed frame with empty queue");

                        frame_id = exp_queue.pop_front();
                        generate_frame(frame_id, input_re, input_im);
                        calc_expected_frame(input_re, input_im, expected_re, expected_im);

                        frame_failed = 1'b0;

                        for (int bin_index = 0; bin_index < FFT_N; bin_index += 1) begin
                            expected_word = pack_sample(expected_re[bin_index], expected_im[bin_index]);

                            if (got_words[bin_index] !== expected_word) begin
                                fails_count = fails_count + 1;
                                frame_failed = 1'b1;
                                report_fail(
                                    frame_id,
                                    bin_index,
                                    input_re[bin_index],
                                    input_im[bin_index],
                                    got_words[bin_index],
                                    expected_re[bin_index],
                                    expected_im[bin_index]
                                );
                            end
                        end

                        if (!frame_failed)
                            report_pass(frame_id);

                        got_count = 0;

                        if (drive_done && (exp_queue.size() == 0)) begin
                            check_done = 1'b1;
                            return;
                        end
                    end
                end else if (drive_done && (exp_queue.size() == 0) && (got_count == 0)) begin
                    check_done = 1'b1;
                    return;
                end
            end
        end
    endtask

    fft64_core #(
        .TDATA_W(TDATA_W)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata (m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready)
    );

    initial begin
        clk = 1'b0;
        forever #(HALF_CLK_PERIOD_NS) clk = ~clk;
    end

    initial begin
        repeat (WATCHDOG_CYCLES) @(posedge clk);
        $fatal(1, "fft64_core_dpi_tb: TIMEOUT");
    end

    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "../build/fft64_core_dpi_tb.vcd";

        if (!$value$plusargs("frames=%d", frames_limit))
            frames_limit = DEFAULT_FRAMES;

        if (!$value$plusargs("seed=%d", seed))
            seed = DEFAULT_SEED;

        if (!$value$plusargs("backoff_db=%f", backoff_db))
            backoff_db = DEFAULT_BACKOFF_DB;

        if (frames_limit <= 0)
            $fatal(1, "fft64_core_dpi_tb: frames must be > 0");

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, fft64_core_dpi_tb);
        end

        rst = 1'b1;
        s_axis_tdata = '0;
        s_axis_tvalid = 1'b0;
        m_axis_tready = 1'b0;
        frames_count = 0;
        fails_count = 0;
        drive_done = 1'b0;
        check_done = 1'b0;

        $display(
            "Mode: frames=%0d seed=%0d backoff_db=%0.3f",
            frames_limit,
            seed,
            backoff_db
        );

        repeat (RESET_CYCLES) @(posedge clk);
        rst = 1'b0;
        m_axis_tready = 1'b1;

        fork
            drive_task();
            check_task();
        join

        $display("DONE: frames=%0d fails=%0d", frames_count, fails_count);

        if (fails_count != 0)
            $fatal(1, "fft64_core_dpi_tb: FAILED");

        $finish;
    end

endmodule
