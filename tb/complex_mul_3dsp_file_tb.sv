`timescale 1ns/1ps

import radix2_types_pkg::*;

// Testbench for complex_mul_3dsp.
// Потоковый режим: новый вектор X/Y подается каждый такт.
// Проверка выхода выполняется с задержкой OUTPUT_OFFSET_CYCLES.
// Формат комплексного входа в файле: {imag[31:16], real[15:0]}.
module complex_mul_3dsp_file_tb #(
    parameter int RESET_CYCLES  = 4,  // Количество тактов удержания rst=1
    parameter int CLK_PERIOD_NS = 10, // Период clk в ns
    parameter int OUTPUT_OFFSET_CYCLES = 4 // Латентность DUT в тактах
);

    localparam int HALF_CLK_PERIOD_NS  = CLK_PERIOD_NS / 2;
    // Индекс "хвоста" pipeline ожидаемых значений (точка сравнения с DUT).
    localparam int PIPE_LAST = OUTPUT_OFFSET_CYCLES - 1;

    logic clk;
    logic rst;

    // Интерфейс DUT.
    complex16_t x;
    complex16_t y;
    complex33_t out;

    // Служебные переменные для чтения файла и статистики.
    integer file_desc;
    integer scan_status;
    integer vectors_count;
    integer fails_count;

    // Буферы сырых/приведенных входных значений.
    logic [31:0] x_raw;
    logic [31:0] y_raw;
    reg [1023:0] skipped_line;

    // Pipeline ожидаемых результатов на OUTPUT_OFFSET_CYCLES стадий.
    // valid_pipe[i] показывает, что в стадии i есть валидный вектор.
    // id_pipe/x_pipe/y_pipe нужны для удобного PASS/FAIL лога.
    // exp_out_pipe хранит эталон для сравнения с выходом DUT.
    logic                   valid_pipe [0:PIPE_LAST];
    integer                 id_pipe    [0:PIPE_LAST];
    complex16_t             x_pipe     [0:PIPE_LAST];
    complex16_t             y_pipe     [0:PIPE_LAST];
    complex33_t             exp_out_pipe[0:PIPE_LAST];

    string input_file;
    string dumpfile;

    // Эталонный комплексный результат:
    // Re = ar*br - ai*bi
    // Im = ar*bi + ai*br
    // Q16.0 * Q2.14 => Q19.14 (signed [32:0]).
    function automatic complex33_t calc_expected_out(
        input complex16_t x_in,
        input complex16_t y_in
    );
        complex33_comp_t p0, p1;
        complex33_t      out_expected;
        begin
            p0 = x_in.re * y_in.re;
            p1 = x_in.im * y_in.im;
            out_expected.re = $signed(p0) - $signed(p1);

            p0 = x_in.re * y_in.im;
            p1 = x_in.im * y_in.re;
            out_expected.im = $signed(p0) + $signed(p1);

            calc_expected_out = out_expected;
        end
    endfunction

    function automatic complex16_comp_t packed_re16(input complex16_t v);
        begin
            packed_re16 = v.re;
        end
    endfunction

    function automatic complex16_comp_t packed_im16(input complex16_t v);
        begin
            packed_im16 = v.im;
        end
    endfunction

    function automatic real q2_14_to_real(input complex16_comp_t v);
        begin
            q2_14_to_real = $itor(v) / (1 << 14);
        end
    endfunction

    function automatic real q19_14_to_real(input complex33_comp_t v);
        longint signed wide_v;
        begin
            wide_v = v;
            q19_14_to_real = real'(wide_v) / (1 << 14);
        end
    endfunction

    task automatic print_pass_result(
        input int vec_id,
        input complex16_t x_in,
        input complex16_t y_in,
        input complex33_t out_in
    );
        begin
            $display("PASS vec=%0d", vec_id);
            $display(
                "  a   = %0d + j%0d    (x=0x%08h)",
                packed_re16(x_in),
                packed_im16(x_in),
                x_in
            );
            $display(
                "  b   = %0d + j%0d    (y=0x%08h, Q2.14 => %0.6f + j%0.6f)",
                packed_re16(y_in),
                packed_im16(y_in),
                y_in,
                q2_14_to_real(packed_re16(y_in)),
                q2_14_to_real(packed_im16(y_in))
            );
            $display(
                "  out = %0d + j%0d    (Q19.14 => %0.6f + j%0.6f)",
                out_in.re,
                out_in.im,
                q19_14_to_real(out_in.re),
                q19_14_to_real(out_in.im)
            );
        end
    endtask

    task automatic print_fail_result(
        input int vec_id,
        input complex16_t x_in,
        input complex16_t y_in,
        input complex33_t got_in,
        input complex33_t exp_in
    );
        begin
            $display("FAIL vec=%0d", vec_id);
            $display(
                "  a    = %0d + j%0d    (x=0x%08h)",
                packed_re16(x_in),
                packed_im16(x_in),
                x_in
            );
            $display(
                "  b    = %0d + j%0d    (y=0x%08h, Q2.14 => %0.6f + j%0.6f)",
                packed_re16(y_in),
                packed_im16(y_in),
                y_in,
                q2_14_to_real(packed_re16(y_in)),
                q2_14_to_real(packed_im16(y_in))
            );
            $display(
                "  got  = %0d + j%0d    (Q19.14 => %0.6f + j%0.6f)",
                got_in.re,
                got_in.im,
                q19_14_to_real(got_in.re),
                q19_14_to_real(got_in.im)
            );
            $display(
                "  exp  = %0d + j%0d    (Q19.14 => %0.6f + j%0.6f)",
                exp_in.re,
                exp_in.im,
                q19_14_to_real(exp_in.re),
                q19_14_to_real(exp_in.im)
            );
        end
    endtask

    // Загружает вход DUT на текущий такт.
    task automatic drive_vector(
        input complex16_t x_in,
        input complex16_t y_in
    );
        begin
            x = x_in;
            y = y_in;
        end
    endtask

    complex_mul_3dsp dut (
        .clk (clk),
        .rst (rst),
        .x   (x),
        .y   (y),
        .out (out)
    );

    // Генерация тактового сигнала.
    initial clk = 1'b0;
    always #(HALF_CLK_PERIOD_NS) clk = ~clk;

    // Включение VCD по плюсаргам:
    // +dump и опционально +dumpfile=<path>.
    initial begin
        if (!$value$plusargs("dumpfile=%s", dumpfile))
            dumpfile = "tb/build/complex_mul_3dsp_file_tb.vcd";

        if ($test$plusargs("dump")) begin
            $dumpfile(dumpfile);
            $dumpvars(0, complex_mul_3dsp_file_tb);
            $display("[%0t] VCD enabled: %0s", $time, dumpfile);
        end
    end

    // Основной сценарий TB:
    // 1) reset + инициализация pipeline;
    // 2) каждый цикл подаем новый вектор;
    // 3) сравниваем выход DUT с "хвостом" pipeline эталонов;
    // 4) после EOF делаем flush и завершаем тест.
    initial begin
        bit got_vector;
        bit eof_reached;
        bit done;
        integer flush_left;
        int i;

        // Начальная инициализация.
        rst         = 1'b1;
        x           = '0;
        y           = '0;
        vectors_count = 0;
        fails_count   = 0;
        eof_reached   = 1'b0;
        done          = 1'b0;
        flush_left    = OUTPUT_OFFSET_CYCLES;

        // Очистка pipeline ожидаемых результатов.
        for (i = 0; i < OUTPUT_OFFSET_CYCLES; i++) begin
            valid_pipe[i]  = 1'b0;
            id_pipe[i]     = 0;
            x_pipe[i]      = '0;
            y_pipe[i]      = '0;
            exp_out_pipe[i] = '0;
        end

        if (!$value$plusargs("infile=%s", input_file))
            input_file = "tb/input/input_complex_vectors.txt";

        file_desc = $fopen(input_file, "r");
        if (file_desc == 0) begin
            $fatal(1, "Cannot open input file: %0s", input_file);
        end

        $display("[%0t] Reading vectors from: %0s", $time, input_file);
        $display("[%0t] File format per line: X Y (hex, packed as {imag[31:16], real[15:0]})", $time);
        $display("[%0t] Output offset: %0d cycles", $time, OUTPUT_OFFSET_CYCLES);
        $display("[%0t] Drive mode: one new vector each clock cycle", $time);

        repeat (RESET_CYCLES) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        while (!done) begin
            @(negedge clk);

            // Шаг 1: проверяем текущий выход DUT против хвоста pipeline.
            if (valid_pipe[PIPE_LAST]) begin
                if (out !== exp_out_pipe[PIPE_LAST]) begin
                    fails_count = fails_count + 1;
                    print_fail_result(
                        id_pipe[PIPE_LAST],
                        x_pipe[PIPE_LAST],
                        y_pipe[PIPE_LAST],
                        out,
                        exp_out_pipe[PIPE_LAST]
                    );
                end else begin
                    print_pass_result(
                        id_pipe[PIPE_LAST],
                        x_pipe[PIPE_LAST],
                        y_pipe[PIPE_LAST],
                        out
                    );
                end
            end

            // Шаг 2: сдвигаем pipeline на одну стадию вперед.
            for (i = PIPE_LAST; i > 0; i--) begin
                valid_pipe[i]  = valid_pipe[i-1];
                id_pipe[i]     = id_pipe[i-1];
                x_pipe[i]      = x_pipe[i-1];
                y_pipe[i]      = y_pipe[i-1];
                exp_out_pipe[i] = exp_out_pipe[i-1];
            end

            // Шаг 3: stage0 по умолчанию делаем пустым.
            // Если ниже успешно прочитаем новый вектор, stage0 перезапишется.
            valid_pipe[0]  = 1'b0;
            id_pipe[0]     = 0;
            x_pipe[0]      = '0;
            y_pipe[0]      = '0;
            exp_out_pipe[0] = '0;

            if (!eof_reached) begin
                // Шаг 4: читаем следующий валидный вектор из файла.
                // Невалидные/комментные строки пропускаются.
                got_vector = 1'b0;
                while (!got_vector && !$feof(file_desc)) begin
                    scan_status = $fscanf(file_desc, "%h %h\n", x_raw, y_raw);
                    if (scan_status == 2) begin
                        got_vector = 1'b1;
                    end else if (!$feof(file_desc)) begin
                        scan_status = $fgets(skipped_line, file_desc);
                        if (scan_status == 0)
                            $fatal(1, "Failed to skip malformed line in: %0s", input_file);
                        $write("[%0t] Skipping malformed input line: %0s", $time, skipped_line);
                    end
                end

                if (got_vector) begin
                    // Шаг 5: подаем вектор в DUT и кладем эталон в stage0.
                    vectors_count = vectors_count + 1;

                    drive_vector(
                        radix2_types_pkg::bits_to_complex16(x_raw),
                        radix2_types_pkg::bits_to_complex16(y_raw)
                    );

                    valid_pipe[0]  = 1'b1;
                    id_pipe[0]     = vectors_count;
                    x_pipe[0]      = radix2_types_pkg::bits_to_complex16(x_raw);
                    y_pipe[0]      = radix2_types_pkg::bits_to_complex16(y_raw);
                    exp_out_pipe[0] = calc_expected_out(x_pipe[0], y_pipe[0]);
                end else begin
                    // Шаг 6: EOF достигнут, начинаем flush pipeline нулями.
                    eof_reached = 1'b1;
                    drive_vector('0, '0);
                    flush_left = flush_left - 1;
                    if (flush_left == 0)
                        done = 1'b1;
                end
            end else begin
                // Продолжаем flush до полного выхода всех валидных стадий.
                drive_vector('0, '0);
                flush_left = flush_left - 1;
                if (flush_left == 0)
                    done = 1'b1;
            end
        end

        // Финал теста: закрываем файл и выдаем итог.
        $fclose(file_desc);

        $display("DONE: vectors=%0d fails=%0d", vectors_count, fails_count);
        // Ненулевой fails_count делает тест fail.
        if (fails_count != 0) begin
            $fatal(1, "complex_mul_3dsp_file_tb: FAILED");
        end
        $finish;
    end

endmodule
