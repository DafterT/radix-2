`timescale 1ns/1ps

import radix2_types_pkg::*;

module radix2_fft_stage_tb #(
    parameter int FFT_N         = 64,
    parameter int RESET_CYCLES  = 4,
    parameter int CLK_PERIOD_NS = 10,
    parameter int NUM_STIM      = 6
);

    localparam int HALF_CLK_PERIOD_NS = CLK_PERIOD_NS / 2;

    logic clk;
    logic rst;
    logic valid_i;
    logic last_i;
    complex16_t a_i;
    complex16_t b_i;
    logic       valid_o;
    logic       last_o;
    complex16_t a_o;
    complex16_t b_o;

    complex16_t stim_a    [0:NUM_STIM-1];
    complex16_t stim_b    [0:NUM_STIM-1];
    logic       stim_valid[0:NUM_STIM-1];
    logic       stim_last [0:NUM_STIM-1];

    int stim_idx;
    int inputs_seen;
    int outputs_seen;
    int i;

    string dumpfile;

    function automatic real q16_0_to_real(
        input complex16_comp_t value_in
    );
        begin
            q16_0_to_real = $itor(value_in);
        end
    endfunction

    task automatic print_drive_vector(
        input int         vec_idx,
        input logic       valid_in,
        input logic       last_in,
        input complex16_t a_in,
        input complex16_t b_in
    );
        begin
            $display("DRIVE idx=%0d valid=%0b last=%0b", vec_idx, valid_in, last_in);
            $display(
                "  a_i = 0x%08h  =>  %0.6f + j%0.6f  (Q16.0)",
                a_in,
                q16_0_to_real(a_in.re),
                q16_0_to_real(a_in.im)
            );
            $display(
                "  b_i = 0x%08h  =>  %0.6f + j%0.6f  (Q16.0)",
                b_in,
                q16_0_to_real(b_in.re),
                q16_0_to_real(b_in.im)
            );
        end
    endtask

    task automatic print_output_vector(
        input int         vec_idx,
        input logic       valid_in,
        input logic       last_in,
        input complex16_t a_in,
        input complex16_t b_in
    );
        begin
            $display("OUT  idx=%0d valid=%0b last=%0b", vec_idx, valid_in, last_in);
            $display(
                "  a_o = 0x%08h  =>  %0.6f + j%0.6f  (Q16.0)",
                a_in,
                q16_0_to_real(a_in.re),
                q16_0_to_real(a_in.im)
            );
            $display(
                "  b_o = 0x%08h  =>  %0.6f + j%0.6f  (Q16.0)",
                b_in,
                q16_0_to_real(b_in.re),
                q16_0_to_real(b_in.im)
            );
        end
    endtask

    task automatic init_stimulus;
        begin
            for (i = 0; i < NUM_STIM; i++) begin
                stim_a[i]     = '0;
                stim_b[i]     = '0;
                stim_valid[i] = 1'b0;
                stim_last[i]  = 1'b0;
            end

            // Edit stimulus here.
            stim_a[0]     = radix2_types_pkg::comp_t_to_complex16(16'sd10, 16'sd2);
            stim_b[0]     = radix2_types_pkg::comp_t_to_complex16(16'sd3, 16'sd4);
            stim_valid[0] = 1'b1;

            stim_a[1]     = radix2_types_pkg::comp_t_to_complex16(16'sd7, -16'sd3);
            stim_b[1]     = radix2_types_pkg::comp_t_to_complex16(-16'sd2, 16'sd1);
            stim_valid[1] = 1'b1;

            stim_a[2]     = radix2_types_pkg::comp_t_to_complex16(-16'sd8, 16'sd5);
            stim_b[2]     = radix2_types_pkg::comp_t_to_complex16(16'sd2, -16'sd6);
            stim_valid[2] = 1'b1;
            stim_last[2]  = 1'b1;

            stim_a[3]     = radix2_types_pkg::comp_t_to_complex16(16'sd0, 16'sd0);
            stim_b[3]     = radix2_types_pkg::comp_t_to_complex16(16'sd0, 16'sd0);
            stim_valid[3] = 1'b0;

            stim_a[4]     = radix2_types_pkg::comp_t_to_complex16(-16'sd1, -16'sd1);
            stim_b[4]     = radix2_types_pkg::comp_t_to_complex16(16'sd2, 16'sd2);
            stim_valid[4] = 1'b1;

            stim_a[5]     = radix2_types_pkg::comp_t_to_complex16(16'sd4, 16'sd1);
            stim_b[5]     = radix2_types_pkg::comp_t_to_complex16(16'sd1, -16'sd3);
            stim_valid[5] = 1'b1;
            stim_last[5]  = 1'b1;
        end
    endtask

    radix2_fft_stage #(
        .FFT_N(FFT_N)
    ) dut (
        .clk    (clk),
        .rst    (rst),
        .valid_i(valid_i),
        .last_i (last_i),
        .a_i    (a_i),
        .b_i    (b_i),
        .valid_o(valid_o),
        .last_o (last_o),
        .a_o    (a_o),
        .b_o    (b_o)
    );

    initial clk = 1'b0;
    always #(HALF_CLK_PERIOD_NS) clk = ~clk;

    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "tb/build/radix2_fft_stage_tb.vcd";

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, radix2_fft_stage_tb);
            $display("[%0t] VCD enabled: %0s", $time, dumpfile);
        end
    end

    initial begin
        rst          = 1'b1;
        valid_i      <= 1'b0;
        last_i       <= 1'b0;
        a_i          <= '0;
        b_i          <= '0;
        stim_idx     = 0;
        inputs_seen  = 0;
        outputs_seen = 0;

        init_stimulus();

        repeat (RESET_CYCLES) @(posedge clk);
        rst <= 1'b0;

        while ((stim_idx < NUM_STIM) || (outputs_seen < inputs_seen)) begin
            @(posedge clk);

            if (valid_o) begin
                outputs_seen = outputs_seen + 1;
                print_output_vector(outputs_seen, valid_o, last_o, a_o, b_o);
            end

            if (stim_idx < NUM_STIM) begin
                valid_i <= stim_valid[stim_idx];
                last_i  <= stim_last[stim_idx];
                a_i     <= stim_a[stim_idx];
                b_i     <= stim_b[stim_idx];

                print_drive_vector(
                    stim_idx + 1,
                    stim_valid[stim_idx],
                    stim_last[stim_idx],
                    stim_a[stim_idx],
                    stim_b[stim_idx]
                );

                if (stim_valid[stim_idx])
                    inputs_seen = inputs_seen + 1;

                stim_idx = stim_idx + 1;
            end else begin
                valid_i <= 1'b0;
                last_i  <= 1'b0;
                a_i     <= '0;
                b_i     <= '0;
            end
        end

        $display("DONE: inputs=%0d outputs=%0d", inputs_seen, outputs_seen);
        $finish;
    end

endmodule
