`timescale 1ns/1ps

module fft_twiddle_rom
#(
    parameter int FFT_N     = 64,
    parameter int FRAC_BITS = 14,
    parameter int TW_W      = 16,

    //   0 -> twiddle_bankers()
    //   1 -> twiddle_twmeminit()
    parameter int TW_GEN_MODE = 0
)
(
    input  logic                         clk,
    input  logic [$clog2(FFT_N/2)-1:0]   addr,
    output logic [2*TW_W-1:0]            w
);

    localparam int  DEPTH = FFT_N / 2;
    localparam real PI    = 3.14159265358979323846;
    localparam real EPS   = 1.0e-12;

    // {imag, real}
    (* rom_style = "distributed" *)
    logic [2*TW_W-1:0] rom [0:DEPTH-1];

    //------------------------------------------------------------------------------
    // Банковское округление для НЕОТРИЦАТЕЛЬНОГО числа:
    //  - frac < 0.5  -> вниз
    //  - frac > 0.5  -> вверх
    //  - frac = 0.5  -> к ближайшему четному
    //------------------------------------------------------------------------------
    function automatic longint unsigned bankers_round_positive(input real value);
        longint unsigned integer_part;
        real             fractional_part;
    begin
        // value >= 0
        integer_part    = $unsigned(longint'($rtoi(value)));
        fractional_part = value - real'(integer_part);

        if (fractional_part < (0.5 - EPS)) begin
            bankers_round_positive = integer_part;
        end
        else if (fractional_part > (0.5 + EPS)) begin
            bankers_round_positive = integer_part + 1;
        end
        else begin
            // Ровно половина: округляем к четному
            if (integer_part[0] == 1'b0)
                bankers_round_positive = integer_part;
            else
                bankers_round_positive = integer_part + 1;
        end
    end
    endfunction

    //------------------------------------------------------------------------------
    // Перевод real -> signed fixed-point с банковским округлением
    //------------------------------------------------------------------------------
    function automatic logic signed [TW_W-1:0] real_to_fixed_bankers(input real x);
        bit              is_negative;
        real             abs_x;
        real             scaled_abs_x;
        longint unsigned rounded_magnitude;
        longint signed   signed_result;
    begin
        is_negative      = (x < 0.0);
        abs_x            = is_negative ? -x : x;
        scaled_abs_x     = abs_x * (1 << FRAC_BITS);
        rounded_magnitude = bankers_round_positive(scaled_abs_x);

        signed_result = longint'(rounded_magnitude);
        if (is_negative)
            signed_result = -signed_result;

        real_to_fixed_bankers = $signed(signed_result[TW_W-1:0]);
    end
    endfunction

    function automatic logic signed [TW_W-1:0] real_to_fixed_cast(input real x);
        int signed fixed_value;
    begin
        fixed_value = int'(x * (2**FRAC_BITS));
        real_to_fixed_cast = $signed(fixed_value[TW_W-1:0]);
    end
    endfunction

    function automatic logic [2*TW_W-1:0] twiddle_bankers(input int idx);
        real angle;
        real data_real;
        real data_imag;
    begin
        angle     = 2.0 * PI * real'(idx) / real'(FFT_N);
        data_real =  $cos(angle);
        data_imag = -$sin(angle);

        twiddle_bankers = {
            real_to_fixed_bankers(data_imag),
            real_to_fixed_bankers(data_real)
        };
    end
    endfunction

    function automatic logic [2*TW_W-1:0] twiddle_twmeminit(input int idx);
        real angel;
        real data_real;
        real data_imag;
    begin
        angel     = 2.0 * PI * $itor(idx) / $itor(FFT_N);
        data_real =  $cos(angel);
        data_imag = -$sin(angel);

        twiddle_twmeminit = {
            real_to_fixed_cast(data_imag),
            real_to_fixed_cast(data_real)
        };
    end
    endfunction

    // TW_GEN_MODE:
    //   0 -> twiddle_bankers()
    //   1 -> twiddle_twmeminit()
    function automatic logic [2*TW_W-1:0] twiddle_value(input int idx);
    begin
        case (TW_GEN_MODE)
            0:       twiddle_value = twiddle_bankers(idx);
            1:       twiddle_value = twiddle_twmeminit(idx);
            default: twiddle_value = '0;
        endcase
    end
    endfunction

    //--------------------------------------------------------------------------
    // Проверки параметров
    //--------------------------------------------------------------------------
    initial begin
        if (FFT_N < 4)
            $fatal(1, "fft_twiddle_rom: FFT_N must be >= 4");

        if ((FFT_N & (FFT_N - 1)) != 0)
            $fatal(1, "fft_twiddle_rom: FFT_N must be power of two");

        if (TW_W < FRAC_BITS + 2)
            $fatal(1, "fft_twiddle_rom: TW_W must be >= FRAC_BITS + 2 for Q2.%0d", FRAC_BITS);

        if ((TW_GEN_MODE < 0) || (TW_GEN_MODE > 1))
            $fatal(1, "fft_twiddle_rom: TW_GEN_MODE must be 0 or 1");
    end

    //--------------------------------------------------------------------------
    // Инициализация:
    // W_N^k = exp(-j*2*pi*k/N)
    // Re =  cos(2*pi*k/N)
    // Im = -sin(2*pi*k/N)
    //--------------------------------------------------------------------------
    initial begin
        for (int i = 0; i < DEPTH; i++)
            rom[i] = twiddle_value(i);
    end

    //--------------------------------------------------------------------------
    // Синхронный выход ROM
    //--------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        w <= rom[addr];
    end

endmodule
