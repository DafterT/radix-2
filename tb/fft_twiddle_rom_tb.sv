`timescale 1ns/1ps

module fft_twiddle_rom_tb #(
    parameter int FFT_N = 64,
    parameter int FRAC_BITS = 14,
    parameter int TW_W = 16,
    parameter int TW_GEN_MODE = 0,
    parameter int CLK_PERIOD_NS = 10
);
    localparam int DEPTH = FFT_N / 2;
    localparam int ADDR_W = $clog2(DEPTH);
    localparam int HALF_CLK_PERIOD_NS = CLK_PERIOD_NS / 2;

    logic clk;
    logic [ADDR_W-1:0] addr;
    logic [2*TW_W-1:0] w;
    logic [TW_W-1:0] w_re_raw;
    logic [TW_W-1:0] w_im_raw;
    logic signed [TW_W-1:0] w_re;
    logic signed [TW_W-1:0] w_im;

    integer idx;
    string dumpfile;

    fft_twiddle_rom #(
        .FFT_N(FFT_N),
        .FRAC_BITS(FRAC_BITS),
        .TW_W(TW_W),
        .TW_GEN_MODE(TW_GEN_MODE)
    ) dut (
        .clk(clk),
        .addr(addr),
        .w(w)
    );

    assign w_re_raw = w[TW_W-1:0];
    assign w_im_raw = w[2*TW_W-1:TW_W];
    assign w_re     = $signed(w_re_raw);
    assign w_im     = $signed(w_im_raw);

    function automatic real fixed_to_real(input logic signed [TW_W-1:0] val);
        begin
            fixed_to_real = $itor($signed(val)) / (1 << FRAC_BITS);
        end
    endfunction

    initial clk = 1'b0;
    always #(HALF_CLK_PERIOD_NS) clk = ~clk;

    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "tb/build/fft_twiddle_rom_tb.vcd";

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, fft_twiddle_rom_tb);
            $display("[%0t] VCD enabled: %0s", $time, dumpfile);
        end
    end

    initial begin
        addr = '0;

        // Read all ROM words through synchronous output.
        @(negedge clk);
        $display(
            "[%0t] Dump twiddle ROM: FFT_N=%0d DEPTH=%0d FRAC_BITS=%0d TW_W=%0d TW_GEN_MODE=%0d",
            $time, FFT_N, DEPTH, FRAC_BITS, TW_W, TW_GEN_MODE
        );
        $display("idx addr raw_hex imag_int imag_real real_int real_real");

        for (idx = 0; idx < DEPTH; idx = idx + 1) begin
            addr = idx[ADDR_W-1:0];
            @(posedge clk);
            #1;
            $display(
                "%0d %0d 0x%0h %0d %0.8f %0d %0.8f",
                idx,
                addr,
                w,
                w_im,
                fixed_to_real(w_im),
                w_re,
                fixed_to_real(w_re)
            );
        end

        $display("[%0t] DONE: dumped=%0d", $time, DEPTH);
        $finish;
    end

endmodule
