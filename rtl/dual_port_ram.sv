`timescale 1ns/1ps

module dual_port_ram
#(
    parameter int DEPTH = 64,
    parameter int WIDTH = 16,
    localparam int ADDR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1
)
(
    input  logic               clk,
    input  logic               we_a,
    input  logic [ADDR_W-1:0]  addr_a,
    input  logic [WIDTH-1:0]   din_a,
    output logic [WIDTH-1:0]   dout_a,
    input  logic               we_b,
    input  logic [ADDR_W-1:0]  addr_b,
    input  logic [WIDTH-1:0]   din_b,
    output logic [WIDTH-1:0]   dout_b
);

    initial begin
        if (DEPTH <= 0)
            $fatal(1, "dual_port_ram: DEPTH must be > 0");

        if (WIDTH <= 0)
            $fatal(1, "dual_port_ram: WIDTH must be > 0");
    end

    logic [WIDTH-1:0] mem [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (we_a)
            mem[addr_a] <= din_a;

        if (we_b)
            mem[addr_b] <= din_b;

        dout_a <= mem[addr_a];
        dout_b <= mem[addr_b];
    end

endmodule
