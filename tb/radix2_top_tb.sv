`timescale 1ns/1ps

module radix2_top_tb
#(
    parameter int FFT_N         = 64,
    parameter int FRAC_BITS     = 14,
    parameter int TW_W          = 16,
    parameter int ROUND_OWID    = 18,
    parameter int OUT_W         = 16,
    parameter int RESET_CYCLES  = 4,
    parameter int CLK_PERIOD_NS = 10,
    parameter int VALID_LATENCY = 5,
    parameter int TIMEOUT_CYCLES = 64
);

    localparam int DEPTH               = FFT_N / 2;
    localparam int ADDR_W              = $clog2(DEPTH);
    localparam int HALF_CLK_PERIOD_NS  = CLK_PERIOD_NS / 2;
    localparam int PIPE_LAST           = VALID_LATENCY - 1;
    localparam int ROUND_TRUNC         = 32 - ROUND_OWID;
    localparam int NUM_STIM            = 8;
    localparam real PI                 = 3.14159265358979323846;
    localparam real EPS                = 1.0e-12;

    logic clk;
    logic rst;

    logic signed [31:0] iq;
    logic               valid_i;
    logic               last_i;
    logic signed [15:0] im;
    logic signed [15:0] re;
    logic               valid_o;

    logic signed [31:0] stim_iq   [0:NUM_STIM-1];
    logic               stim_valid[0:NUM_STIM-1];
    logic               stim_last [0:NUM_STIM-1];

    logic               exp_valid_pipe[0:PIPE_LAST];
    logic signed [15:0] exp_re_pipe   [0:PIPE_LAST];
    logic signed [15:0] exp_im_pipe   [0:PIPE_LAST];

    logic [ADDR_W-1:0] expected_addr_q;
    logic signed [31:0] twiddle_ref;
    logic signed [31:0] mul_re_ref;
    logic signed [31:0] mul_im_ref;
    logic signed [ROUND_OWID-1:0] round_re_ref;
    logic signed [ROUND_OWID-1:0] round_im_ref;

    integer stim_idx;
    integer cycle_count;
    integer inputs_accepted;
    integer outputs_seen;
    integer fails_count;
    integer i;
    bit pending_expected;
    bit done;

    reg [1023:0] dumpfile;

    radix2_top #(
        .FFT_N     (FFT_N),
        .FRAC_BITS (FRAC_BITS),
        .TW_W      (TW_W),
        .ROUND_OWID(ROUND_OWID),
        .OUT_W     (OUT_W)
    ) dut (
        .clk    (clk),
        .rst    (rst),
        .iq     (iq),
        .valid_i(valid_i),
        .last_i (last_i),
        .im     (im),
        .re     (re),
        .valid_o(valid_o)
    );

    function automatic logic signed [31:0] pack_complex(
        input logic signed [15:0] im_in,
        input logic signed [15:0] re_in
    );
        begin
            pack_complex = {im_in, re_in};
        end
    endfunction

    function automatic longint unsigned bankers_round_positive(input real value);
        longint unsigned integer_part;
        real             fractional_part;
    begin
        integer_part    = $rtoi(value);
        fractional_part = value - integer_part;

        if (fractional_part < (0.5 - EPS)) begin
            bankers_round_positive = integer_part;
        end
        else if (fractional_part > (0.5 + EPS)) begin
            bankers_round_positive = integer_part + 1;
        end
        else begin
            if (integer_part[0] == 1'b0)
                bankers_round_positive = integer_part;
            else
                bankers_round_positive = integer_part + 1;
        end
    end
    endfunction

    function automatic logic signed [TW_W-1:0] real_to_fixed_bankers(input real x);
        bit              is_negative;
        real             abs_x;
        real             scaled_abs_x;
        longint unsigned rounded_magnitude;
        longint signed   signed_result;
    begin
        is_negative       = (x < 0.0);
        abs_x             = is_negative ? -x : x;
        scaled_abs_x      = abs_x * (1 << FRAC_BITS);
        rounded_magnitude = bankers_round_positive(scaled_abs_x);

        if (is_negative)
            signed_result = -longint'(rounded_magnitude);
        else
            signed_result = longint'(rounded_magnitude);

        real_to_fixed_bankers = signed_result[TW_W-1:0];
    end
    endfunction

    function automatic logic signed [31:0] twiddle_at_addr(
        input logic [ADDR_W-1:0] addr
    );
        real angle;
        real re_v;
        real im_v;
    begin
        angle = 2.0 * PI * $itor(addr) / FFT_N;
        re_v  = $cos(angle);
        im_v  = -$sin(angle);

        twiddle_at_addr = {
            real_to_fixed_bankers(im_v),
            real_to_fixed_bankers(re_v)
        };
    end
    endfunction

    function automatic logic signed [31:0] calc_expected_mul_re(
        input logic signed [31:0] x_in,
        input logic signed [31:0] y_in
    );
        logic signed [15:0] a_re;
        logic signed [15:0] a_im;
        logic signed [15:0] b_re;
        logic signed [15:0] b_im;
        logic signed [31:0] p0;
        logic signed [31:0] p1;
    begin
        a_im = $signed(x_in[31:16]);
        a_re = $signed(x_in[15:0]);
        b_im = $signed(y_in[31:16]);
        b_re = $signed(y_in[15:0]);

        p0 = a_re * b_re;
        p1 = a_im * b_im;

        calc_expected_mul_re = $signed(p0) - $signed(p1);
    end
    endfunction

    function automatic logic signed [31:0] calc_expected_mul_im(
        input logic signed [31:0] x_in,
        input logic signed [31:0] y_in
    );
        logic signed [15:0] a_re;
        logic signed [15:0] a_im;
        logic signed [15:0] b_re;
        logic signed [15:0] b_im;
        logic signed [31:0] p0;
        logic signed [31:0] p1;
    begin
        a_im = $signed(x_in[31:16]);
        a_re = $signed(x_in[15:0]);
        b_im = $signed(y_in[31:16]);
        b_re = $signed(y_in[15:0]);

        p0 = a_re * b_im;
        p1 = a_im * b_re;

        calc_expected_mul_im = $signed(p0) + $signed(p1);
    end
    endfunction

    function automatic logic signed [ROUND_OWID-1:0] round_convergent_ref(
        input logic signed [31:0] i_data
    );
        logic signed [31:0] w_convergent;
    begin
        w_convergent =
            i_data
            + {
                {ROUND_OWID{1'b0}},
                i_data[ROUND_TRUNC],
                {(ROUND_TRUNC-1){!i_data[ROUND_TRUNC]}}
              };

        round_convergent_ref = w_convergent[31:ROUND_TRUNC];
    end
    endfunction

    function automatic logic signed [OUT_W-1:0] clip_ref(
        input logic signed [ROUND_OWID-1:0] i_data
    );
        localparam logic signed [ROUND_OWID-1:0] MAX_VAL = (1 << (OUT_W - 1)) - 1;
        localparam logic signed [ROUND_OWID-1:0] MIN_VAL = -MAX_VAL;
    begin
        if (i_data > MAX_VAL)
            clip_ref = $signed(MAX_VAL[OUT_W-1:0]);
        else if (i_data < MIN_VAL)
            clip_ref = $signed(MIN_VAL[OUT_W-1:0]);
        else
            clip_ref = $signed(i_data[OUT_W-1:0]);
    end
    endfunction

    task automatic init_stimulus;
        begin
            for (i = 0; i < NUM_STIM; i++) begin
                stim_iq[i]    = '0;
                stim_valid[i] = 1'b0;
                stim_last[i]  = 1'b0;
            end

            stim_iq[0]    = pack_complex(16'sd10, 16'sd10);
            stim_valid[0] = 1'b1;

            stim_iq[1]    = pack_complex(16'sd10, 16'sd10);
            stim_valid[1] = 1'b1;

            stim_iq[3]    = pack_complex(16'sd10, 16'sd10);
            stim_valid[3] = 1'b1;

            stim_iq[4]    = pack_complex(16'sd10, 16'sd10);
            stim_valid[4] = 1'b1;
            stim_last[4]  = 1'b1;

            stim_iq[6]    = pack_complex(16'sd10, 16'sd10);
            stim_valid[6] = 1'b1;

            stim_iq[7]    = pack_complex(16'sd10, 16'sd10);
            stim_valid[7] = 1'b1;
            stim_last[7]  = 1'b1;
        end
    endtask

    initial clk = 1'b0;
    always #(HALF_CLK_PERIOD_NS) clk = ~clk;

    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "tb/build/radix2_top_tb.vcd";

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, radix2_top_tb);
            $display("[%0t] VCD enabled: %0s", $time, dumpfile);
        end
    end

    initial begin
        rst             = 1'b1;
        iq              = '0;
        valid_i         = 1'b0;
        last_i          = 1'b0;
        expected_addr_q = '0;
        stim_idx        = 0;
        cycle_count     = 0;
        inputs_accepted = 0;
        outputs_seen    = 0;
        fails_count     = 0;
        done            = 1'b0;

        init_stimulus();

        for (i = 0; i < VALID_LATENCY; i++) begin
            exp_valid_pipe[i] = 1'b0;
            exp_re_pipe[i]    = '0;
            exp_im_pipe[i]    = '0;
        end

        repeat (RESET_CYCLES) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        while (!done) begin
            if (dut.twiddle_addr !== expected_addr_q) begin
                fails_count = fails_count + 1;
                $display(
                    "FAIL cycle=%0d: addr_o=%0d exp_addr=%0d valid_i=%0b last_i=%0b",
                    cycle_count,
                    dut.twiddle_addr,
                    expected_addr_q,
                    valid_i,
                    last_i
                );
            end

            if (exp_valid_pipe[PIPE_LAST]) begin
                if (!valid_o) begin
                    fails_count = fails_count + 1;
                    $display(
                        "FAIL cycle=%0d: missing valid_o exp_re=%0d exp_im=%0d",
                        cycle_count,
                        $signed(exp_re_pipe[PIPE_LAST]),
                        $signed(exp_im_pipe[PIPE_LAST])
                    );
                end else begin
                    outputs_seen = outputs_seen + 1;
                    if ((re !== exp_re_pipe[PIPE_LAST]) || (im !== exp_im_pipe[PIPE_LAST])) begin
                        fails_count = fails_count + 1;
                        $display(
                            "FAIL cycle=%0d: got(re=%0d im=%0d) exp(re=%0d im=%0d)",
                            cycle_count,
                            $signed(re),
                            $signed(im),
                            $signed(exp_re_pipe[PIPE_LAST]),
                            $signed(exp_im_pipe[PIPE_LAST])
                        );
                    end else begin
                        $display(
                            "PASS cycle=%0d: re=%0d im=%0d",
                            cycle_count,
                            $signed(re),
                            $signed(im)
                        );
                    end
                end
            end else if (valid_o) begin
                fails_count = fails_count + 1;
                outputs_seen = outputs_seen + 1;
                $display(
                    "FAIL cycle=%0d: unexpected valid_o with re=%0d im=%0d",
                    cycle_count,
                    $signed(re),
                    $signed(im)
                );
            end

            for (i = PIPE_LAST; i > 0; i--) begin
                exp_valid_pipe[i] = exp_valid_pipe[i-1];
                exp_re_pipe[i]    = exp_re_pipe[i-1];
                exp_im_pipe[i]    = exp_im_pipe[i-1];
            end

            exp_valid_pipe[0] = 1'b0;
            exp_re_pipe[0]    = '0;
            exp_im_pipe[0]    = '0;

            if (stim_idx < NUM_STIM) begin
                iq      = stim_iq[stim_idx];
                valid_i = stim_valid[stim_idx];
                last_i  = stim_last[stim_idx];

                if (stim_valid[stim_idx]) begin
                    twiddle_ref  = twiddle_at_addr(expected_addr_q);
                    mul_re_ref   = calc_expected_mul_re(stim_iq[stim_idx], twiddle_ref);
                    mul_im_ref   = calc_expected_mul_im(stim_iq[stim_idx], twiddle_ref);
                    round_re_ref = round_convergent_ref(mul_re_ref);
                    round_im_ref = round_convergent_ref(mul_im_ref);

                    exp_valid_pipe[0] = 1'b1;
                    exp_re_pipe[0]    = clip_ref(round_re_ref);
                    exp_im_pipe[0]    = clip_ref(round_im_ref);
                    inputs_accepted   = inputs_accepted + 1;

                    if (stim_last[stim_idx] || (expected_addr_q == ADDR_W'(DEPTH - 1)))
                        expected_addr_q = '0;
                    else
                        expected_addr_q = expected_addr_q + 1'b1;
                end

                stim_idx = stim_idx + 1;
            end else begin
                iq      = '0;
                valid_i = 1'b0;
                last_i  = 1'b0;
            end

            pending_expected = 1'b0;
            for (i = 0; i < VALID_LATENCY; i++) begin
                if (exp_valid_pipe[i])
                    pending_expected = 1'b1;
            end

            if ((stim_idx >= NUM_STIM) && !pending_expected && (outputs_seen == inputs_accepted))
                done = 1'b1;

            cycle_count = cycle_count + 1;
            if (!done && (cycle_count >= TIMEOUT_CYCLES))
                $fatal(1, "radix2_top_tb: TIMEOUT after %0d cycles", TIMEOUT_CYCLES);

            if (!done)
                @(negedge clk);
        end

        $display(
            "DONE: inputs=%0d outputs=%0d fails=%0d",
            inputs_accepted,
            outputs_seen,
            fails_count
        );

        if (outputs_seen != inputs_accepted)
            $fatal(1, "radix2_top_tb: output count mismatch");

        if (fails_count != 0)
            $fatal(1, "radix2_top_tb: FAILED");

        $finish;
    end

endmodule
