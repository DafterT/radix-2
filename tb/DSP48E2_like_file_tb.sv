`timescale 1ns/1ps

module DSP48E2_like_file_tb #(
    parameter bit PREADD_SUB = 1'b0,
    parameter bit POSTADD_EN = 1'b0,
    parameter bit POSTADD_SUB = 1'b0,
    parameter int RESET_CYCLES = 4,
    parameter int CLK_PERIOD_NS = 10,
    parameter int FLUSH_CYCLES = 6
);

    localparam int HALF_CLK_PERIOD_NS = CLK_PERIOD_NS / 2;
    localparam int C_DELAY_CYCLES     = 3;
    localparam int OUTPUT_OFFSET_CYCLES = C_DELAY_CYCLES + 1;

    logic clk;
    logic rst;

    logic signed [29:0] A;
    logic signed [26:0] D;
    logic signed [17:0] B;
    logic signed [47:0] C;
    logic signed [47:0] Y;
    logic signed [47:0] c_pipe0;
    logic signed [47:0] c_pipe1;
    logic signed [47:0] c_pipe2;

    integer file_desc;
    integer scan_status;
    integer vectors_count;

    integer a_val;
    integer d_val;
    integer b_val;
    longint c_val;
    logic signed [29:0] a_vec;
    logic signed [26:0] d_vec;
    logic signed [17:0] b_vec;
    logic signed [47:0] c_vec;
    integer vec_id;
    reg [1023:0] skipped_line;

    string input_file;
    string dumpfile;

    task automatic drive_vector(
        input logic signed [29:0] a_in,
        input logic signed [26:0] d_in,
        input logic signed [17:0] b_in,
        input logic signed [47:0] c_in
    );
        begin
            A = a_in;
            D = d_in;
            B = b_in;

            // C must be delayed by 3 cycles to match A/D/B internal pipeline.
            C       = c_pipe2;
            c_pipe2 = c_pipe1;
            c_pipe1 = c_pipe0;
            c_pipe0 = c_in;
        end
    endtask

    task automatic print_vector_result(
        input int vec_id,
        input logic signed [29:0] a_in,
        input logic signed [26:0] d_in,
        input logic signed [17:0] b_in,
        input logic signed [47:0] c_in
    );
        begin
            repeat (OUTPUT_OFFSET_CYCLES) @(posedge clk);
            @(negedge clk);
            $display(
                "vec=%0d: A=%0d D=%0d B=%0d C=%0d -> Y=%0d",
                vec_id, a_in, d_in, b_in, c_in, Y
            );
        end
    endtask

    DSP48E2_like #(
        .PREADD_SUB (PREADD_SUB),
        .POSTADD_EN (POSTADD_EN),
        .POSTADD_SUB(POSTADD_SUB)
    ) dut (
        .clk(clk),
        .rst(rst),
        .A  (A),
        .D  (D),
        .B  (B),
        .C  (C),
        .Y  (Y)
    );

    initial clk = 1'b0;
    always #(HALF_CLK_PERIOD_NS) clk = ~clk;

    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "tb/build/DSP48E2_like_file_tb.vcd";

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, DSP48E2_like_file_tb);
            $display("[%0t] VCD enabled: %0s", $time, dumpfile);
        end
    end

    initial begin
        rst         = 1'b1;
        A           = '0;
        D           = '0;
        B           = '0;
        C           = '0;
        c_pipe0     = '0;
        c_pipe1     = '0;
        c_pipe2     = '0;
        vectors_count = 0;

        if (!$value$plusargs("infile=%s", input_file))
            input_file = "tb/input/input_vectors.txt";

        file_desc = $fopen(input_file, "r");
        if (file_desc == 0) begin
            $fatal(1, "Cannot open input file: %0s", input_file);
        end
        $display("[%0t] Reading vectors from: %0s", $time, input_file);
        $display("[%0t] File format per line: A D B C (signed decimal)", $time);
        $display("[%0t] Console trace: input -> output with offset=%0d cycles", $time, OUTPUT_OFFSET_CYCLES);

        repeat (RESET_CYCLES) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        while (!$feof(file_desc)) begin
            scan_status = $fscanf(file_desc, "%d %d %d %d\n", a_val, d_val, b_val, c_val);
            if (scan_status == 4) begin
                @(negedge clk);
                a_vec = $signed(a_val[29:0]);
                d_vec = $signed(d_val[26:0]);
                b_vec = $signed(b_val[17:0]);
                c_vec = $signed(c_val[47:0]);

                drive_vector(a_vec, d_vec, b_vec, c_vec);
                vectors_count = vectors_count + 1;
                vec_id = vectors_count;

                fork
                    print_vector_result(
                        vec_id,
                        a_vec,
                        d_vec,
                        b_vec,
                        c_vec
                    );
                join_none
            end else begin
                if (!$feof(file_desc)) begin
                    scan_status = $fgets(skipped_line, file_desc);
                    if (scan_status == 0)
                        $fatal(1, "Failed to skip malformed line in: %0s", input_file);
                    $display("[%0t] Skipping malformed input line: %0s", $time, skipped_line);
                end
            end
        end

        $fclose(file_desc);

        repeat (FLUSH_CYCLES) begin
            @(negedge clk);
            drive_vector('0, '0, '0, '0);
        end
        @(posedge clk);

        $display(
            "DONE: vectors=%0d c_delay=%0d flush=%0d preadd_sub=%0d postadd_en=%0d postadd_sub=%0d",
            vectors_count, C_DELAY_CYCLES, FLUSH_CYCLES, PREADD_SUB, POSTADD_EN, POSTADD_SUB
        );
        $finish;
    end

endmodule
