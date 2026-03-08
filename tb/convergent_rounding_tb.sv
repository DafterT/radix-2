`timescale 1ns/1ps

module convergent_rounding_tb;

    localparam int IWID = 8;
    localparam int OWID = 4;
    localparam int TRUNC = IWID - OWID;
    localparam int NUM_TESTS = 32;

    logic signed [IWID-1:0] i_data;
    logic signed [OWID-1:0] o_data;

    logic signed [IWID-1:0] test_input    [0:NUM_TESTS-1];
    logic signed [OWID-1:0] test_expected [0:NUM_TESTS-1];

    int test_idx;
    int fails_count;

    reg [1023:0] dumpfile;

    convergent_rounding #(
        .IWID(IWID),
        .OWID(OWID)
    ) dut (
        .i_data(i_data),
        .o_data(o_data)
    );

    function automatic real fixed_to_real(input logic signed [IWID-1:0] val);
        begin
            fixed_to_real = $itor($signed(val)) / (1 << TRUNC);
        end
    endfunction

    task automatic init_vectors;
        begin
            // Positive values (Q4.4): exact, normal and tie-to-even cases.
            test_input[0]  = 8'sd0;     test_expected[0]  = 4'sd0;   // 0.0000 -> 0
            test_input[1]  = 8'sd7;     test_expected[1]  = 4'sd0;   // 0.4375 -> 0
            test_input[2]  = 8'sd8;     test_expected[2]  = 4'sd0;   // 0.5000 -> 0 (tie, even)
            test_input[3]  = 8'sd9;     test_expected[3]  = 4'sd1;   // 0.5625 -> 1
            test_input[4]  = 8'sd23;    test_expected[4]  = 4'sd1;   // 1.4375 -> 1
            test_input[5]  = 8'sd24;    test_expected[5]  = 4'sd2;   // 1.5000 -> 2 (tie, even)
            test_input[6]  = 8'sd25;    test_expected[6]  = 4'sd2;   // 1.5625 -> 2
            test_input[7]  = 8'sd40;    test_expected[7]  = 4'sd2;   // 2.5000 -> 2 (tie, even)
            test_input[8]  = 8'sd41;    test_expected[8]  = 4'sd3;   // 2.5625 -> 3
            test_input[9]  = 8'sd56;    test_expected[9]  = 4'sd4;   // 3.5000 -> 4 (tie, even)
            test_input[10] = 8'sd72;    test_expected[10] = 4'sd4;   // 4.5000 -> 4 (tie, even)
            test_input[11] = 8'sd88;    test_expected[11] = 4'sd6;   // 5.5000 -> 6 (tie, even)
            test_input[12] = 8'sd104;   test_expected[12] = 4'sd6;   // 6.5000 -> 6 (tie, even)
            test_input[13] = 8'sd111;   test_expected[13] = 4'sd7;   // 6.9375 -> 7
            test_input[14] = 8'sd112;   test_expected[14] = 4'sd7;   // 7.0000 -> 7
            test_input[15] = 8'sd119;   test_expected[15] = 4'sd7;   // 7.4375 -> 7

            // Negative values (Q4.4): exact, normal and tie-to-even cases.
            test_input[16] = -8'sd7;    test_expected[16] = 4'sd0;   // -0.4375 -> 0
            test_input[17] = -8'sd8;    test_expected[17] = 4'sd0;   // -0.5000 -> 0 (tie, even)
            test_input[18] = -8'sd9;    test_expected[18] = -4'sd1;  // -0.5625 -> -1
            test_input[19] = -8'sd23;   test_expected[19] = -4'sd1;  // -1.4375 -> -1
            test_input[20] = -8'sd24;   test_expected[20] = -4'sd2;  // -1.5000 -> -2 (tie, even)
            test_input[21] = -8'sd25;   test_expected[21] = -4'sd2;  // -1.5625 -> -2
            test_input[22] = -8'sd40;   test_expected[22] = -4'sd2;  // -2.5000 -> -2 (tie, even)
            test_input[23] = -8'sd41;   test_expected[23] = -4'sd3;  // -2.5625 -> -3
            test_input[24] = -8'sd56;   test_expected[24] = -4'sd4;  // -3.5000 -> -4 (tie, even)
            test_input[25] = -8'sd72;   test_expected[25] = -4'sd4;  // -4.5000 -> -4 (tie, even)
            test_input[26] = -8'sd88;   test_expected[26] = -4'sd6;  // -5.5000 -> -6 (tie, even)
            test_input[27] = -8'sd104;  test_expected[27] = -4'sd6;  // -6.5000 -> -6 (tie, even)
            test_input[28] = -8'sd111;  test_expected[28] = -4'sd7;  // -6.9375 -> -7
            test_input[29] = -8'sd119;  test_expected[29] = -4'sd7;  // -7.4375 -> -7
            test_input[30] = -8'sd127;  test_expected[30] = 4'sh8;   // -7.9375 -> -8
            test_input[31] = 8'sh80;    test_expected[31] = 4'sh8;   // -8.0000 -> -8
        end
    endtask

    task automatic run_one_test(input int idx);
        begin
            i_data = test_input[idx];
            #1;

            if ($signed(o_data) !== $signed(test_expected[idx])) begin
                fails_count = fails_count + 1;
                $display(
                    "FAIL idx=%0d: in=0b%b.%b, x=%0.4f (raw=%0d) -> got=%0d exp=%0d",
                    idx,
                    test_input[idx][IWID-1:TRUNC],
                    test_input[idx][TRUNC-1:0],
                    fixed_to_real(test_input[idx]),
                    $signed(test_input[idx]),
                    $signed(o_data),
                    $signed(test_expected[idx])
                );
            end else begin
                $display(
                    "PASS idx=%0d: in=0b%b.%b, x=%0.4f (raw=%0d) -> out=%0d",
                    idx,
                    test_input[idx][IWID-1:TRUNC],
                    test_input[idx][TRUNC-1:0],
                    fixed_to_real(test_input[idx]),
                    $signed(test_input[idx]),
                    $signed(o_data)
                );
            end
        end
    endtask

    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "tb/build/convergent_rounding_tb.vcd";

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, convergent_rounding_tb);
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
            $fatal(1, "convergent_rounding_tb: FAILED");

        $finish;
    end

endmodule
