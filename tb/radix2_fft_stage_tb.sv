`timescale 1ns/1ps

import radix2_types_pkg::*;

module radix2_fft_stage_tb #(
    parameter int FFT_N         = 64,
    parameter int RESET_CYCLES  = 4,
    parameter int CLK_PERIOD_NS = 10,
    parameter int MAX_STIM      = 1024
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

    complex16_t stim_a    [0:MAX_STIM-1];
    complex16_t stim_b    [0:MAX_STIM-1];
    logic       stim_valid[0:MAX_STIM-1];
    logic       stim_last [0:MAX_STIM-1];

    int stim_idx;
    int num_stim;
    int inputs_seen;
    int outputs_seen;
    int i;

    string dumpfile;
    string input_file;

    function automatic integer q16_0_to_int(
        input complex16_comp_t value_in
    );
        begin
            q16_0_to_int = value_in;
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
                "  a_i = 0x%08h  =>  %0d + j%0d  (Q16.0)",
                a_in,
                q16_0_to_int(a_in.re),
                q16_0_to_int(a_in.im)
            );
            $display(
                "  b_i = 0x%08h  =>  %0d + j%0d  (Q16.0)",
                b_in,
                q16_0_to_int(b_in.re),
                q16_0_to_int(b_in.im)
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
                "  a_o = 0x%08h  =>  %0d + j%0d  (Q16.0)",
                a_in,
                q16_0_to_int(a_in.re),
                q16_0_to_int(a_in.im)
            );
            $display(
                "  b_o = 0x%08h  =>  %0d + j%0d  (Q16.0)",
                b_in,
                q16_0_to_int(b_in.re),
                q16_0_to_int(b_in.im)
            );
        end
    endtask

    task automatic load_stimulus_from_file;
        int file_desc;
        int line_status;
        int scan_status;
        int valid_raw;
        int last_raw;
        int a_re_raw;
        int a_im_raw;
        int b_re_raw;
        int b_im_raw;
        reg [8*256-1:0] line;
        begin
            for (i = 0; i < MAX_STIM; i++) begin
                stim_a[i]     = '0;
                stim_b[i]     = '0;
                stim_valid[i] = 1'b0;
                stim_last[i]  = 1'b0;
            end

            num_stim = 0;

            if (!$value$plusargs("infile=%s", input_file))
                input_file = "input/fixed_stage_stim.txt";

            file_desc = $fopen(input_file, "r");
            if (file_desc == 0)
                $fatal(1, "Failed to open stage stimulus file: %0s", input_file);

            while (!$feof(file_desc)) begin
                line = "";
                line_status = $fgets(line, file_desc);
                if (line_status != 0) begin
                    scan_status = $sscanf(
                        line,
                        "%d %d %d %d %d %d",
                        valid_raw,
                        last_raw,
                        a_re_raw,
                        a_im_raw,
                        b_re_raw,
                        b_im_raw
                    );

                    if (scan_status == 6) begin
                        if (num_stim >= MAX_STIM)
                            $fatal(1, "Too many stage stimulus vectors in %0s", input_file);

                        stim_a[num_stim] = radix2_types_pkg::comp_t_to_complex16(
                            complex16_comp_t'(a_re_raw),
                            complex16_comp_t'(a_im_raw)
                        );
                        stim_b[num_stim] = radix2_types_pkg::comp_t_to_complex16(
                            complex16_comp_t'(b_re_raw),
                            complex16_comp_t'(b_im_raw)
                        );
                        stim_valid[num_stim] = (valid_raw != 0);
                        stim_last[num_stim]  = (last_raw != 0);
                        num_stim = num_stim + 1;
                    end
                end
            end

            $fclose(file_desc);

            if (num_stim == 0)
                $fatal(1, "No stage stimulus vectors loaded from %0s", input_file);
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
        num_stim     = 0;
        inputs_seen  = 0;
        outputs_seen = 0;

        load_stimulus_from_file();

        repeat (RESET_CYCLES) @(posedge clk);
        rst <= 1'b0;

        while ((stim_idx < num_stim) || (outputs_seen < inputs_seen)) begin
            @(posedge clk);

            if (valid_o) begin
                outputs_seen = outputs_seen + 1;
                print_output_vector(outputs_seen, valid_o, last_o, a_o, b_o);
            end

            if (stim_idx < num_stim) begin
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
