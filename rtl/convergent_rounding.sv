//------------------------------------------------------------------------------
// Convergent rounding (banker's rounding)
//------------------------------------------------------------------------------
// Данный модуль реализует банковское округление (round half to even)
// при уменьшении разрядности фиксированного числа.
//
// Используемая формула округления заимствованы из статьи:
// https://zipcpu.com/dsp/2017/07/22/rounding.html
//------------------------------------------------------------------------------

module convergent_rounding
#(
    parameter int IWID = 32, // Входная ширина
    parameter int OWID = 18  // Выходная ширина
)
(
    input  logic [IWID-1:0] i_data,
    output logic [OWID-1:0] o_data
);

    localparam int TRUNC = IWID - OWID;

    // Проверка параметров
    initial if (IWID <= OWID) $error("Convergent_rounding: IWID must be greater than OWID");

    logic [IWID-1:0] w_convergent;

    assign w_convergent =
        i_data
        + {
            {OWID{1'b0}},
            i_data[TRUNC],
            {(TRUNC-1){!i_data[TRUNC]}}
          };

    assign o_data = w_convergent[IWID-1:TRUNC];

endmodule
