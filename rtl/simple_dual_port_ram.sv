`timescale 1ns/1ps

module simple_dual_port_ram
#(
    parameter int DEPTH = 64,
    parameter int WIDTH = 16,
    localparam int ADDR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1
)
(
    input  logic               clk,
    input  logic               we,
    input  logic [ADDR_W-1:0]  waddr,
    input  logic [WIDTH-1:0]   din,
    input  logic               re,
    input  logic [ADDR_W-1:0]  raddr,
    output logic [WIDTH-1:0]   dout
);

    initial begin
        if (DEPTH <= 0)
            $fatal(1, "simple_dual_port_ram: DEPTH must be > 0");

        if (WIDTH <= 0)
            $fatal(1, "simple_dual_port_ram: WIDTH must be > 0");
    end

    (* ram_style = "block" *) logic [WIDTH-1:0] mem [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (we)
            mem[waddr] <= din;
    end

    always_ff @(posedge clk) begin
        if (re)
            dout <= mem[raddr];
    end

endmodule
