`timescale 1ns/1ps

module radix2_cu_test
#(
    parameter int TDATA_W = 32
)
(
    input  logic               clk,
    input  logic               rst,
    input  logic [TDATA_W-1:0] s_axis_tdata,
    input  logic               s_axis_tvalid,
    output logic               s_axis_tready,
    output logic [TDATA_W-1:0] m_axis_tdata,
    output logic               m_axis_tvalid,
    input  logic               m_axis_tready
);

    typedef enum logic [1:0] {
        ST_CAPTURE,
        ST_READ_PRIME,
        ST_READ_LATCH,
        ST_SEND
    } state_t;

    localparam int FFT_N    = 64;
    localparam int BANK_CNT = 2;
    localparam int INDEX_W  = $clog2(FFT_N);
    localparam int DEPTH    = FFT_N / BANK_CNT;
    localparam int ADDR_W   = $clog2(DEPTH);
    localparam logic [INDEX_W-1:0] LAST_INDEX = FFT_N - 1;

    state_t                 state_q;
    state_t                 state_d;
    logic [INDEX_W-1:0]     wr_index_q;
    logic [INDEX_W-1:0]     wr_index_d;
    logic [INDEX_W-1:0]     rd_index_q;
    logic [INDEX_W-1:0]     rd_index_d;
    logic [TDATA_W-1:0]     out_data_q;
    logic [TDATA_W-1:0]     out_data_d;
    logic [INDEX_W-1:0]     wr_logical_index;
    logic                   wr_bank_sel;
    logic [ADDR_W-1:0]      wr_addr_sel;
    logic                   capture_fire;
    logic                   send_fire;
    logic [TDATA_W-1:0]     rd_capture_data;
    logic                   bank0_we_a;
    logic [ADDR_W-1:0]      bank0_addr_a;
    logic [TDATA_W-1:0]     bank0_din_a;
    logic [ADDR_W-1:0]      bank0_addr_b;
    logic [TDATA_W-1:0]     bank0_dout_b;
    logic                   bank1_we_a;
    logic [ADDR_W-1:0]      bank1_addr_a;
    logic [TDATA_W-1:0]     bank1_din_a;
    logic [ADDR_W-1:0]      bank1_addr_b;
    logic [TDATA_W-1:0]     bank1_dout_b;

    initial begin
        if (TDATA_W <= 0)
            $fatal(1, "radix2_cu_test: TDATA_W must be > 0");
    end

    function automatic logic [5:0] reverse_bits(
        input logic [5:0] value_in
    );
        begin
            reverse_bits = {
                value_in[0],
                value_in[1],
                value_in[2],
                value_in[3],
                value_in[4],
                value_in[5]
            };
        end
    endfunction

    function automatic logic resolve_bank(
        input logic [INDEX_W-1:0] logical_index
    );
        begin
            resolve_bank = ^logical_index;
        end
    endfunction

    function automatic logic [ADDR_W-1:0] resolve_addr(
        input logic [INDEX_W-1:0] logical_index
    );
        begin
            resolve_addr = logical_index[ADDR_W-1:0];
        end
    endfunction

    assign wr_logical_index = reverse_bits(wr_index_q);
    assign wr_bank_sel      = resolve_bank(wr_logical_index);
    assign wr_addr_sel      = resolve_addr(wr_logical_index);
    assign capture_fire     = s_axis_tvalid && s_axis_tready;
    assign send_fire        = m_axis_tvalid && m_axis_tready;
    assign rd_capture_data  = resolve_bank(rd_index_q) ? bank1_dout_b : bank0_dout_b;

    dual_port_ram #(
        .DEPTH(DEPTH),
        .WIDTH(TDATA_W)
    ) u_bank0_ram (
        .clk   (clk),
        .we_a  (bank0_we_a),
        .addr_a(bank0_addr_a),
        .din_a (bank0_din_a),
        .dout_a(),
        .we_b  (1'b0),
        .addr_b(bank0_addr_b),
        .din_b ('0),
        .dout_b(bank0_dout_b)
    );

    dual_port_ram #(
        .DEPTH(DEPTH),
        .WIDTH(TDATA_W)
    ) u_bank1_ram (
        .clk   (clk),
        .we_a  (bank1_we_a),
        .addr_a(bank1_addr_a),
        .din_a (bank1_din_a),
        .dout_a(),
        .we_b  (1'b0),
        .addr_b(bank1_addr_b),
        .din_b ('0),
        .dout_b(bank1_dout_b)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            state_q    <= ST_CAPTURE;
            wr_index_q <= '0;
            rd_index_q <= '0;
            out_data_q <= '0;
        end else begin
            state_q    <= state_d;
            wr_index_q <= wr_index_d;
            rd_index_q <= rd_index_d;
            out_data_q <= out_data_d;
        end
    end

    always_comb begin
        state_d      = state_q;
        wr_index_d   = wr_index_q;
        rd_index_d   = rd_index_q;
        out_data_d   = out_data_q;
        s_axis_tready = 1'b0;
        m_axis_tdata  = out_data_q;
        m_axis_tvalid = 1'b0;

        bank0_we_a   = 1'b0;
        bank0_addr_a = wr_addr_sel;
        bank0_din_a  = s_axis_tdata;
        bank0_addr_b = resolve_addr(rd_index_q);

        bank1_we_a   = 1'b0;
        bank1_addr_a = wr_addr_sel;
        bank1_din_a  = s_axis_tdata;
        bank1_addr_b = resolve_addr(rd_index_q);

        case (state_q)
            ST_CAPTURE: begin
                s_axis_tready = 1'b1;

                if (capture_fire) begin
                    if (wr_bank_sel)
                        bank1_we_a = 1'b1;
                    else
                        bank0_we_a = 1'b1;

                    if (wr_index_q == LAST_INDEX) begin
                        wr_index_d = '0;
                        rd_index_d = '0;
                        state_d    = ST_READ_PRIME;
                    end else begin
                        wr_index_d = wr_index_q + 1'b1;
                    end
                end
            end

            ST_READ_PRIME: begin
                // dual_port_ram has synchronous read, so the first read address needs a priming cycle.
                state_d = ST_READ_LATCH;
            end

            ST_READ_LATCH: begin
                out_data_d = rd_capture_data;
                state_d    = ST_SEND;
            end

            ST_SEND: begin
                m_axis_tvalid = 1'b1;

                if (send_fire) begin
                    if (rd_index_q == LAST_INDEX) begin
                        wr_index_d = '0;
                        rd_index_d = '0;
                        state_d    = ST_CAPTURE;
                    end else begin
                        rd_index_d   = rd_index_q + 1'b1;
                        bank0_addr_b = resolve_addr(rd_index_q + 1'b1);
                        bank1_addr_b = resolve_addr(rd_index_q + 1'b1);
                        state_d      = ST_READ_LATCH;
                    end
                end
            end

            default: begin
                state_d = ST_CAPTURE;
            end
        endcase
    end

endmodule
