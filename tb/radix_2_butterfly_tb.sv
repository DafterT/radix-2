`timescale 1ns/1ps

module radix_2_butterfly_tb #(
    parameter int RESET_CYCLES           = 4,
    parameter int CLK_PERIOD_NS          = 10,
    parameter int NUM_VECTORS            = 4
);

    localparam int HALF_CLK_PERIOD_NS = CLK_PERIOD_NS / 2;

    logic clk;
    logic rst;
    logic valid_i;

    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] W;
    logic        valid_o;
    logic [65:0] a_out;
    logic [65:0] b_out;

    logic [31:0] stim_a [0:NUM_VECTORS-1];
    logic [31:0] stim_b [0:NUM_VECTORS-1];
    logic [31:0] stim_W [0:NUM_VECTORS-1];

    int stim_idx;
    int outputs_seen;
    int i;

    string dumpfile;

    function automatic logic [31:0] pack_complex_16(
        input logic signed [15:0] im_in,
        input logic signed [15:0] re_in
    );
        begin
            pack_complex_16 = {im_in, re_in};
        end
    endfunction

    function automatic logic signed [32:0] unpack_re_33(
        input logic [65:0] value_in
    );
        begin
            unpack_re_33 = $signed(value_in[32:0]);
        end
    endfunction

    function automatic logic signed [32:0] unpack_im_33(
        input logic [65:0] value_in
    );
        begin
            unpack_im_33 = $signed(value_in[65:33]);
        end
    endfunction

    function automatic logic signed [15:0] unpack_re_16(
        input logic [31:0] value_in
    );
        begin
            unpack_re_16 = $signed(value_in[15:0]);
        end
    endfunction

    function automatic logic signed [15:0] unpack_im_16(
        input logic [31:0] value_in
    );
        begin
            unpack_im_16 = $signed(value_in[31:16]);
        end
    endfunction

    function automatic real q16_0_to_real(
        input logic signed [15:0] value_in
    );
        begin
            q16_0_to_real = $itor(value_in);
        end
    endfunction

    function automatic real q2_14_to_real(
        input logic signed [15:0] value_in
    );
        begin
            q2_14_to_real = $itor(value_in) / (1 << 14);
        end
    endfunction

    function automatic real q19_14_to_real(
        input logic signed [32:0] value_in
    );
        begin
            q19_14_to_real = $itor(value_in) / (1 << 14);
        end
    endfunction

    task automatic print_drive_vector(
        input int         vec_idx,
        input logic [31:0] a_in,
        input logic [31:0] b_in,
        input logic [31:0] W_in
    );
        begin
            $display("DRIVE idx=%0d", vec_idx);
            $display(
                "  a = 0x%08h  =>  %0.6f + j%0.6f  (Q16.0)",
                a_in,
                q16_0_to_real(unpack_re_16(a_in)),
                q16_0_to_real(unpack_im_16(a_in))
            );
            $display(
                "  b = 0x%08h  =>  %0.6f + j%0.6f  (Q16.0)",
                b_in,
                q16_0_to_real(unpack_re_16(b_in)),
                q16_0_to_real(unpack_im_16(b_in))
            );
            $display(
                "  W = 0x%08h  =>  %0.6f + j%0.6f  (Q2.14)",
                W_in,
                q2_14_to_real(unpack_re_16(W_in)),
                q2_14_to_real(unpack_im_16(W_in))
            );
        end
    endtask

    task automatic print_output_vector(
        input int          vec_idx,
        input logic [65:0] a_out_in,
        input logic [65:0] b_out_in
    );
        logic signed [32:0] a_out_re;
        logic signed [32:0] a_out_im;
        logic signed [32:0] b_out_re;
        logic signed [32:0] b_out_im;
        begin
            a_out_re = unpack_re_33(a_out_in);
            a_out_im = unpack_im_33(a_out_in);
            b_out_re = unpack_re_33(b_out_in);
            b_out_im = unpack_im_33(b_out_in);

            $display("OUT  idx=%0d", vec_idx);
            $display(
                "  a_out = 0x%h  =>  %0.6f + j%0.6f  (Q19.14)",
                a_out_in,
                q19_14_to_real(a_out_re),
                q19_14_to_real(a_out_im)
            );
            $display(
                "  b_out = 0x%h  =>  %0.6f + j%0.6f  (Q19.14)",
                b_out_in,
                q19_14_to_real(b_out_re),
                q19_14_to_real(b_out_im)
            );
        end
    endtask

    task automatic init_stimulus;
        begin
            for (i = 0; i < NUM_VECTORS; i++) begin
                stim_a[i] = '0;
                stim_b[i] = '0;
                stim_W[i] = '0;
            end

            // Edit vectors here.
            stim_a[0] = pack_complex_16(16'sd2,  16'sd10);
            stim_b[0] = pack_complex_16(16'sd4,  16'sd3);
            stim_W[0] = pack_complex_16(16'sd0,  16'sh4000); //  1.0 + j0.0

            stim_a[1] = pack_complex_16(-16'sd3, 16'sd7);
            stim_b[1] = pack_complex_16(16'sd1, -16'sd2);
            stim_W[1] = pack_complex_16(16'sh4000, 16'sd0);  //  0.0 + j1.0

            stim_a[2] = pack_complex_16(16'sd5, -16'sd8);
            stim_b[2] = pack_complex_16(-16'sd6, 16'sd2);
            stim_W[2] = pack_complex_16(16'sd0,  16'sh2000); //  0.5 + j0.0

            stim_a[3] = pack_complex_16(-16'sd1, -16'sd1);
            stim_b[3] = pack_complex_16(16'sd2,  16'sd2);
            stim_W[3] = pack_complex_16(-16'sh4000, 16'sd0); //  0.0 - j1.0
        end
    endtask

    radix2_butterfly dut (
        .clk    (clk),
        .rst    (rst),
        .valid_i(valid_i),
        .a      (a),
        .b      (b),
        .W      (W),
        .valid_o(valid_o),
        .a_out  (a_out),
        .b_out  (b_out)
    );

    initial clk = 1'b0;
    always #(HALF_CLK_PERIOD_NS) clk = ~clk;

    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "tb/build/radix_2_butterfly_tb.vcd";

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, radix_2_butterfly_tb);
            $display("[%0t] VCD enabled: %0s", $time, dumpfile);
        end
    end

    initial begin
        rst          = 1'b1;
        valid_i      <= 1'b0;
        a            <= '0;
        b            <= '0;
        W            <= '0;
        stim_idx     = 0;
        outputs_seen = 0;

        init_stimulus();

        repeat (RESET_CYCLES) @(posedge clk);
        rst <= 1'b0;

        while (outputs_seen < NUM_VECTORS) begin
            @(posedge clk);

            if (valid_o) begin
                outputs_seen = outputs_seen + 1;
                print_output_vector(outputs_seen, a_out, b_out);
            end

            if (stim_idx < NUM_VECTORS) begin
                valid_i <= 1'b1;
                a <= stim_a[stim_idx];
                b <= stim_b[stim_idx];
                W <= stim_W[stim_idx];

                print_drive_vector(stim_idx + 1, stim_a[stim_idx], stim_b[stim_idx], stim_W[stim_idx]);

                stim_idx = stim_idx + 1;
            end else begin
                valid_i <= 1'b0;
                a <= '0;
                b <= '0;
                W <= '0;
            end
        end

        $display("DONE: vectors=%0d outputs=%0d", NUM_VECTORS, outputs_seen);
        $finish;
    end

endmodule
