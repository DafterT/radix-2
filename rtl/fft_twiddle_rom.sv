`timescale 1ns/1ps

module fft_twiddle_rom
#(
    parameter int FFT_N     = 64,
    parameter int TW_W      = 16
)
(
    input  logic                         clk,
    input  logic [$clog2(FFT_N/2)-1:0]   addr,
    output logic [2*TW_W-1:0]            w
);

    //--------------------------------------------------------------------------
    // Проверки параметров
    //--------------------------------------------------------------------------
    initial begin
        if (FFT_N < 4)
            $fatal(1, "fft_twiddle_rom: FFT_N must be >= 4");

        if ((FFT_N & (FFT_N - 1)) != 0)
            $fatal(1, "fft_twiddle_rom: FFT_N must be power of two");

        if (TW_W < 2)
            $fatal(1, "fft_twiddle_rom: TW_W must be >= 2");
    end

    localparam int  DEPTH = FFT_N / 2;
    localparam int  FRAC_BITS = TW_W - 2;
    localparam real PI    = 3.14159265358979323846;

    // {imag, real}
    (* rom_style = "distributed" *)
    logic [2*TW_W-1:0] rom [0:DEPTH-1];

    //--------------------------------------------------------------------------
    // Перевод real -> signed fixed-point
    //--------------------------------------------------------------------------
    function automatic logic signed [TW_W-1:0] real_to_fixed_cast(input real x);
        int signed fixed_value;
    begin
        fixed_value = int'(x * (2**FRAC_BITS));
        real_to_fixed_cast = $signed(fixed_value[TW_W-1:0]);
    end
    endfunction

    //--------------------------------------------------------------------------
    // Генерация twiddle-коэффициента в формате twmeminit:
    // W_N^k = exp(-j*2*pi*k/N)
    //--------------------------------------------------------------------------
    function automatic logic [2*TW_W-1:0] twiddle_twmeminit(input int idx);
        real angle;
        real data_real;
        real data_imag;
    begin
        angle     = 2.0 * PI * $itor(idx) / $itor(FFT_N);
        data_real =  $cos(angle);
        data_imag = -$sin(angle);

        twiddle_twmeminit = {
            real_to_fixed_cast(data_imag),
            real_to_fixed_cast(data_real)
        };
    end
    endfunction

    //--------------------------------------------------------------------------
    // Инициализация ROM:
    // W_N^k = exp(-j*2*pi*k/N)
    // Re =  cos(2*pi*k/N)
    // Im = -sin(2*pi*k/N)
    //--------------------------------------------------------------------------
    initial begin
        for (int i = 0; i < DEPTH; i++)
            rom[i] = twiddle_twmeminit(i);
    end

    //--------------------------------------------------------------------------
    // Синхронный выход ROM
    //--------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        w <= rom[addr];
    end

endmodule
