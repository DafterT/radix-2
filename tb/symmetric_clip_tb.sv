`timescale 1ns/1ps

module symmetric_clip_tb;

    localparam int IN_BITS = 5;
    localparam int OUT_BITS = 3;
    localparam int IWID = IN_BITS;
    localparam int OWID = OUT_BITS;
    localparam int NUM_TESTS = 1 << IN_BITS;

    localparam logic signed [IWID-1:0] MAX_VAL = (1 <<< (OWID - 1)) - 1;
    localparam logic signed [IWID-1:0] MIN_VAL = -MAX_VAL;

    logic signed [IWID-1:0] i_data;
    logic signed [OWID-1:0] o_data;

    logic signed [IWID-1:0] test_input    [0:NUM_TESTS-1];
    logic signed [OWID-1:0] test_expected [0:NUM_TESTS-1];

    int test_idx;
    int raw_idx;
    int fails_count;

    string dumpfile;

    symmetric_clip #(
        .IWID(IWID),
        .OWID(OWID)
    ) dut (
        .i_data(i_data),
        .o_data(o_data)
    );

    function automatic logic signed [OWID-1:0] clip_ref(
        input logic signed [IWID-1:0] val
    );
        logic signed [IWID-1:0] clipped;
        begin
            if (val > MAX_VAL)
                clipped = MAX_VAL;
            else if (val < MIN_VAL)
                clipped = MIN_VAL;
            else
                clipped = val;

            clip_ref = $signed(clipped[OWID-1:0]);
        end
    endfunction

    task automatic init_vectors;
        logic [IWID-1:0] raw_code;
        begin
            // Exhaustive test: all 32 codes of 5-bit signed input.
            for (raw_idx = 0; raw_idx < NUM_TESTS; raw_idx = raw_idx + 1) begin
                raw_code = raw_idx[IWID-1:0];
                test_input[raw_idx] = $signed(raw_code);
                test_expected[raw_idx] = clip_ref(test_input[raw_idx]);
            end
        end
    endtask

    task automatic run_one_test(input int idx);
        begin
            i_data = test_input[idx];
            #1;

            if ($signed(o_data) !== $signed(test_expected[idx])) begin
                fails_count = fails_count + 1;
                $display(
                    "FAIL idx=%0d: in=%0d (0b%b) -> got=%0d (0b%b) exp=%0d (0b%b) [clip=%0d..%0d]",
                    idx,
                    $signed(test_input[idx]),
                    test_input[idx],
                    $signed(o_data),
                    o_data,
                    $signed(test_expected[idx]),
                    test_expected[idx],
                    $signed(MIN_VAL),
                    $signed(MAX_VAL)
                );
            end else begin
                $display(
                    "PASS idx=%0d: in=%0d (0b%b) -> out=%0d (0b%b)",
                    idx,
                    $signed(test_input[idx]),
                    test_input[idx],
                    $signed(o_data),
                    o_data
                );
            end
        end
    endtask

    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "tb/build/symmetric_clip_tb.vcd";

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, symmetric_clip_tb);
            $display("[%0t] VCD enabled: %0s", $time, dumpfile);
        end
    end

    initial begin
        i_data = '0;
        fails_count = 0;

        init_vectors();

        for (test_idx = 0; test_idx < NUM_TESTS; test_idx = test_idx + 1)
            run_one_test(test_idx);

        $display("DONE: tests=%0d fails=%0d", NUM_TESTS, fails_count);
        if (fails_count != 0)
            $fatal(1, "symmetric_clip_tb: FAILED");

        $finish;
    end

endmodule
