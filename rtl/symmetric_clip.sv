`timescale 1ns/1ps

module symmetric_clip
#(
    parameter int IWID = 18,
    parameter int OWID = 16
)
(
    input  logic signed [IWID-1:0] i_data,
    output logic signed [OWID-1:0] o_data
);

    initial begin
        if (IWID <= OWID)
            $error("[symmetric_clip]: IWID must be greater than OWID");
        if (OWID < 2)
            $error("[symmetric_clip]: OWID must be at least 2 for signed symmetric clip");
    end

    // For signed OWID-bit output the representable positive maximum is 2^(OWID-1)-1.
    localparam logic signed [IWID-1:0] MAX_VAL = (1 << (OWID - 1)) - 1;
    localparam logic signed [IWID-1:0] MIN_VAL = -MAX_VAL;

    always_comb begin
        if (i_data > MAX_VAL)
            o_data = $signed(MAX_VAL[OWID-1:0]);
        else if (i_data < MIN_VAL)
            o_data = $signed(MIN_VAL[OWID-1:0]);
        else
            o_data = $signed(i_data[OWID-1:0]);
    end

endmodule
