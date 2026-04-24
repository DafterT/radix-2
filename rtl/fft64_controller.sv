`timescale 1ns/1ps

import complex_fixed_pkg::*;

module fft64_controller
#(
    parameter int TDATA_W = 32
)
(
    input  logic               clk,
    input  logic               rst,
    // AXI stream input
    input  logic [TDATA_W-1:0] s_axis_tdata,
    input  logic               s_axis_tvalid,
    output logic               s_axis_tready,
    // AXI stream output
    output logic [TDATA_W-1:0] m_axis_tdata,
    output logic               m_axis_tvalid,
    input  logic               m_axis_tready,
    // Twiddle ROM interface
    output logic [4:0]         twiddle_addr_o,
    // Butterfly unit interface
    output logic               bfly_valid_o,
    output complex16_t         bfly_a_o,
    output complex16_t         bfly_b_o,
    input  logic               bfly_valid_i,
    input  complex16_t         bfly_a_i,
    input  complex16_t         bfly_b_i
);

    initial begin
        if (TDATA_W != $bits(complex16_t))
            $fatal(1, "fft64_controller: TDATA_W must be %0d", $bits(complex16_t));
    end

    typedef enum logic [2:0] {
        ST_CAPTURE,
        ST_STAGE_RUN,
        ST_STAGE_DRAIN,
        ST_OUTPUT_RUN
    } state_t;

    typedef struct packed {
        logic       last_pair;
        logic       top_bank;
        logic [4:0] top_addr;
        logic       bottom_bank;
        logic [4:0] bottom_addr;
    } writeback_meta_t;

    localparam int FFT_N            = 64;
    localparam int STAGE_COUNT      = $clog2(FFT_N);
    localparam int LAST_STAGE       = STAGE_COUNT - 1;
    localparam int STAGE_W          = $clog2(STAGE_COUNT);
    localparam int BANK_CNT         = 2;
    localparam int DEPTH            = FFT_N / BANK_CNT;
    localparam int ADDR_W           = $clog2(DEPTH);
    localparam int INDEX_W          = $clog2(FFT_N);
    localparam int BFLY_LATENCY     = 9;
    localparam int WRITEBACK_META_W = $bits(writeback_meta_t);

    localparam logic [INDEX_W-1:0] LAST_INDEX = FFT_N - 1;
    localparam logic [STAGE_W-1:0] LAST_STAGE_INDEX = LAST_STAGE;

    state_t                 state_q;
    state_t                 state_d;
    logic [INDEX_W-1:0]     wr_index_q;
    logic [INDEX_W-1:0]     wr_index_d;
    logic [STAGE_W-1:0]     stage_index_q;
    logic [STAGE_W-1:0]     stage_index_d;
    logic [INDEX_W-1:0]     stage_block_base_q;
    logic [INDEX_W-1:0]     stage_block_base_d;
    logic [INDEX_W-1:0]     stage_pair_offset_q;
    logic [INDEX_W-1:0]     stage_pair_offset_d;
    logic                   read_valid_q;
    logic                   read_valid_d;
    writeback_meta_t        read_meta_q;
    writeback_meta_t        read_meta_d;
    logic [TDATA_W-1:0]     wr_capture_data;
    logic [INDEX_W-1:0]     wr_logical_index;
    logic                   wr_bank_sel;
    logic [ADDR_W-1:0]      wr_addr_sel;
    logic                   capture_fire;
    logic                   send_fire;
    logic [INDEX_W:0]       out_issue_count_q;
    logic [INDEX_W:0]       out_issue_count_d;
    logic [INDEX_W:0]       out_sent_count_q;
    logic [INDEX_W:0]       out_sent_count_d;
    logic                   out_read_pending_q;
    logic                   out_read_pending_d;
    logic [INDEX_W-1:0]     out_pending_index_q;
    logic [INDEX_W-1:0]     out_pending_index_d;
    logic                   out_main_valid_q;
    logic                   out_main_valid_d;
    logic [TDATA_W-1:0]     out_main_data_q;
    logic [TDATA_W-1:0]     out_main_data_d;
    logic                   out_prefetch_valid_q;
    logic                   out_prefetch_valid_d;
    logic [TDATA_W-1:0]     out_prefetch_data_q;
    logic [TDATA_W-1:0]     out_prefetch_data_d;
    logic [INDEX_W-1:0]     out_issue_index;
    logic [ADDR_W-1:0]      out_issue_addr;
    logic [TDATA_W-1:0]     out_return_data;
    logic [INDEX_W-1:0]     stage_half_span;
    logic [INDEX_W:0]       stage_span;
    logic [INDEX_W-1:0]     twiddle_stride;
    logic [INDEX_W-1:0]     stage_top_index;
    logic [INDEX_W-1:0]     stage_bottom_index;
    logic [INDEX_W-1:0]     stage_twiddle_index;
    logic                   stage_top_bank;
    logic                   stage_bottom_bank;
    logic [ADDR_W-1:0]      stage_top_addr;
    logic [ADDR_W-1:0]      stage_bottom_addr;
    logic                   stage_offset_last;
    logic [INDEX_W:0]       stage_block_limit;
    logic                   stage_block_last;
    logic                   stage_last_pair;
    logic [TDATA_W-1:0]     bank0_dout_b;
    logic [TDATA_W-1:0]     bank1_dout_b;
    logic                   bank0_we_a;
    logic [ADDR_W-1:0]      bank0_addr_a;
    logic [TDATA_W-1:0]     bank0_din_a;
    logic                   bank0_re_b;
    logic [ADDR_W-1:0]      bank0_addr_b;
    logic                   bank1_we_a;
    logic [ADDR_W-1:0]      bank1_addr_a;
    logic [TDATA_W-1:0]     bank1_din_a;
    logic                   bank1_re_b;
    logic [ADDR_W-1:0]      bank1_addr_b;
    logic [WRITEBACK_META_W-1:0] writeback_meta_bits;
    writeback_meta_t        writeback_meta;
    logic                   writeback_meta_valid;
    logic [TDATA_W-1:0]     bfly_a_writeback_bits;
    logic [TDATA_W-1:0]     bfly_b_writeback_bits;
    complex16_t             stage_top_data;
    complex16_t             stage_bottom_data;

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

    assign wr_capture_data   = s_axis_tdata;
    assign wr_logical_index  = reverse_bits(wr_index_q);
    assign wr_bank_sel       = resolve_bank(wr_logical_index);
    assign wr_addr_sel       = resolve_addr(wr_logical_index);
    assign capture_fire      = s_axis_tvalid && s_axis_tready;
    assign send_fire         = m_axis_tvalid && m_axis_tready;
    assign out_issue_index   = out_issue_count_q[INDEX_W-1:0];
    assign out_issue_addr    = resolve_addr(out_issue_index);
    assign out_return_data   = resolve_bank(out_pending_index_q) ? bank1_dout_b : bank0_dout_b;

    assign stage_half_span   = 6'd1 << stage_index_q;
    assign stage_span        = {1'b0, stage_half_span} << 1;
    assign twiddle_stride    = 7'd64 >> (stage_index_q + 1'b1);
    assign stage_top_index   = stage_block_base_q + stage_pair_offset_q;
    assign stage_bottom_index = stage_top_index + stage_half_span;
    assign stage_twiddle_index = stage_pair_offset_q * twiddle_stride;
    assign stage_top_bank    = resolve_bank(stage_top_index);
    assign stage_bottom_bank = resolve_bank(stage_bottom_index);
    assign stage_top_addr    = resolve_addr(stage_top_index);
    assign stage_bottom_addr = resolve_addr(stage_bottom_index);
    assign stage_offset_last = (stage_pair_offset_q == (stage_half_span - 1'b1));
    assign stage_block_limit = {1'b0, stage_block_base_q} + stage_span;
    assign stage_block_last  = (stage_block_limit >= 7'd64);
    assign stage_last_pair   = stage_offset_last && stage_block_last;

    assign stage_top_data = read_meta_q.top_bank
        ? complex_fixed_pkg::bits_to_complex16(bank1_dout_b)
        : complex_fixed_pkg::bits_to_complex16(bank0_dout_b);

    assign stage_bottom_data = read_meta_q.bottom_bank
        ? complex_fixed_pkg::bits_to_complex16(bank1_dout_b)
        : complex_fixed_pkg::bits_to_complex16(bank0_dout_b);

    assign bfly_valid_o = read_valid_q;
    assign bfly_a_o     = read_valid_q ? stage_top_data : '0;
    assign bfly_b_o     = read_valid_q ? stage_bottom_data : '0;
    assign writeback_meta = writeback_meta_t'(writeback_meta_bits);
    assign bfly_a_writeback_bits = bfly_a_i;
    assign bfly_b_writeback_bits = bfly_b_i;

    delay_line_with_valid #(
        .WIDTH(WRITEBACK_META_W),
        .DEPTH(BFLY_LATENCY)
    ) u_writeback_meta_delay (
        .clk     (clk),
        .rst     (rst),
        .in_vld  (read_valid_q),
        .in_data (read_meta_q),
        .out_vld (writeback_meta_valid),
        .out_data(writeback_meta_bits)
    );

    simple_dual_port_ram #(
        .DEPTH(DEPTH),
        .WIDTH(TDATA_W)
    ) u_bank0_ram (
        .clk  (clk),
        .we   (bank0_we_a),
        .waddr(bank0_addr_a),
        .din  (bank0_din_a),
        .re   (bank0_re_b),
        .raddr(bank0_addr_b),
        .dout (bank0_dout_b)
    );

    simple_dual_port_ram #(
        .DEPTH(DEPTH),
        .WIDTH(TDATA_W)
    ) u_bank1_ram (
        .clk  (clk),
        .we   (bank1_we_a),
        .waddr(bank1_addr_a),
        .din  (bank1_din_a),
        .re   (bank1_re_b),
        .raddr(bank1_addr_b),
        .dout (bank1_dout_b)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            state_q            <= ST_CAPTURE;
            wr_index_q         <= '0;
            stage_index_q      <= '0;
            stage_block_base_q <= '0;
            stage_pair_offset_q <= '0;
            read_valid_q       <= 1'b0;
            read_meta_q        <= '0;
            out_issue_count_q  <= '0;
            out_sent_count_q   <= '0;
            out_read_pending_q <= 1'b0;
            out_pending_index_q <= '0;
            out_main_valid_q   <= 1'b0;
            out_main_data_q    <= '0;
            out_prefetch_valid_q <= 1'b0;
            out_prefetch_data_q  <= '0;
        end else begin
            state_q            <= state_d;
            wr_index_q         <= wr_index_d;
            stage_index_q      <= stage_index_d;
            stage_block_base_q <= stage_block_base_d;
            stage_pair_offset_q <= stage_pair_offset_d;
            read_valid_q       <= read_valid_d;
            read_meta_q        <= read_meta_d;
            out_issue_count_q  <= out_issue_count_d;
            out_sent_count_q   <= out_sent_count_d;
            out_read_pending_q <= out_read_pending_d;
            out_pending_index_q <= out_pending_index_d;
            out_main_valid_q   <= out_main_valid_d;
            out_main_data_q    <= out_main_data_d;
            out_prefetch_valid_q <= out_prefetch_valid_d;
            out_prefetch_data_q  <= out_prefetch_data_d;
        end
    end

    always_comb begin
        logic               out_main_valid_tmp;
        logic [TDATA_W-1:0] out_main_data_tmp;
        logic               out_prefetch_valid_tmp;
        logic [TDATA_W-1:0] out_prefetch_data_tmp;

        state_d             = state_q;
        wr_index_d          = wr_index_q;
        stage_index_d       = stage_index_q;
        stage_block_base_d  = stage_block_base_q;
        stage_pair_offset_d = stage_pair_offset_q;
        read_valid_d        = 1'b0;
        read_meta_d         = read_meta_q;
        out_issue_count_d   = out_issue_count_q;
        out_sent_count_d    = out_sent_count_q;
        out_read_pending_d  = 1'b0;
        out_pending_index_d = out_pending_index_q;
        out_main_valid_d    = out_main_valid_q;
        out_main_data_d     = out_main_data_q;
        out_prefetch_valid_d = out_prefetch_valid_q;
        out_prefetch_data_d  = out_prefetch_data_q;
        s_axis_tready       = 1'b0;
        m_axis_tdata        = out_main_data_q;
        m_axis_tvalid       = 1'b0;
        twiddle_addr_o      = '0;

        bank0_we_a   = 1'b0;
        bank0_addr_a = '0;
        bank0_din_a  = '0;
        bank0_re_b   = 1'b0;
        bank0_addr_b = '0;

        bank1_we_a   = 1'b0;
        bank1_addr_a = '0;
        bank1_din_a  = '0;
        bank1_re_b   = 1'b0;
        bank1_addr_b = '0;

        out_main_valid_tmp     = out_main_valid_q;
        out_main_data_tmp      = out_main_data_q;
        out_prefetch_valid_tmp = out_prefetch_valid_q;
        out_prefetch_data_tmp  = out_prefetch_data_q;

        if (writeback_meta_valid && bfly_valid_i) begin
            if (writeback_meta.top_bank) begin
                bank1_we_a   = 1'b1;
                bank1_addr_a = writeback_meta.top_addr;
                bank1_din_a  = bfly_a_writeback_bits;
                bank0_we_a   = 1'b1;
                bank0_addr_a = writeback_meta.bottom_addr;
                bank0_din_a  = bfly_b_writeback_bits;
            end else begin
                bank0_we_a   = 1'b1;
                bank0_addr_a = writeback_meta.top_addr;
                bank0_din_a  = bfly_a_writeback_bits;
                bank1_we_a   = 1'b1;
                bank1_addr_a = writeback_meta.bottom_addr;
                bank1_din_a  = bfly_b_writeback_bits;
            end
        end

        case (state_q)
            ST_CAPTURE: begin
                s_axis_tready = 1'b1;

                if (capture_fire) begin
                    if (wr_bank_sel) begin
                        bank1_we_a   = 1'b1;
                        bank1_addr_a = wr_addr_sel;
                        bank1_din_a  = wr_capture_data;
                    end else begin
                        bank0_we_a   = 1'b1;
                        bank0_addr_a = wr_addr_sel;
                        bank0_din_a  = wr_capture_data;
                    end

                    if (wr_index_q == LAST_INDEX) begin
                        wr_index_d          = '0;
                        stage_index_d       = '0;
                        stage_block_base_d  = '0;
                        stage_pair_offset_d = '0;
                        state_d             = ST_STAGE_RUN;
                    end else begin
                        wr_index_d = wr_index_q + 1'b1;
                    end
                end
            end

            ST_STAGE_RUN: begin
                twiddle_addr_o   = stage_twiddle_index[ADDR_W-1:0];
                read_valid_d     = 1'b1;
                read_meta_d.last_pair   = stage_last_pair;
                read_meta_d.top_bank    = stage_top_bank;
                read_meta_d.top_addr    = stage_top_addr;
                read_meta_d.bottom_bank = stage_bottom_bank;
                read_meta_d.bottom_addr = stage_bottom_addr;

                if (stage_top_bank) begin
                    bank1_re_b   = 1'b1;
                    bank1_addr_b = stage_top_addr;
                    bank0_re_b   = 1'b1;
                    bank0_addr_b = stage_bottom_addr;
                end else begin
                    bank0_re_b   = 1'b1;
                    bank0_addr_b = stage_top_addr;
                    bank1_re_b   = 1'b1;
                    bank1_addr_b = stage_bottom_addr;
                end

                if (stage_offset_last) begin
                    stage_pair_offset_d = '0;

                    if (stage_block_last) begin
                        state_d = ST_STAGE_DRAIN;
                    end else begin
                        stage_block_base_d = stage_block_base_q + stage_span[INDEX_W-1:0];
                    end
                end else begin
                    stage_pair_offset_d = stage_pair_offset_q + 1'b1;
                end
            end

            ST_STAGE_DRAIN: begin
                if (writeback_meta_valid && bfly_valid_i && writeback_meta.last_pair) begin
                    if (stage_index_q == LAST_STAGE_INDEX) begin
                        out_issue_count_d    = '0;
                        out_sent_count_d     = '0;
                        out_read_pending_d   = 1'b1;
                        out_pending_index_d  = '0;
                        out_main_valid_d     = 1'b0;
                        out_main_data_d      = '0;
                        out_prefetch_valid_d = 1'b0;
                        out_prefetch_data_d  = '0;
                        bank0_re_b           = 1'b1;
                        bank0_addr_b         = '0;
                        bank1_re_b           = 1'b1;
                        bank1_addr_b         = '0;
                        out_issue_count_d    = {{INDEX_W{1'b0}}, 1'b1};
                        state_d              = ST_OUTPUT_RUN;
                    end else begin
                        stage_index_d       = stage_index_q + 1'b1;
                        stage_block_base_d  = '0;
                        stage_pair_offset_d = '0;
                        state_d             = ST_STAGE_RUN;
                    end
                end
            end

            ST_OUTPUT_RUN: begin
                m_axis_tdata  = out_main_data_q;
                m_axis_tvalid = out_main_valid_q;

                if (send_fire) begin
                    out_sent_count_d = out_sent_count_q + 1'b1;

                    if (out_prefetch_valid_tmp) begin
                        out_main_data_tmp      = out_prefetch_data_tmp;
                        out_main_valid_tmp     = 1'b1;
                        out_prefetch_data_tmp  = '0;
                        out_prefetch_valid_tmp = 1'b0;
                    end else begin
                        out_main_data_tmp  = '0;
                        out_main_valid_tmp = 1'b0;
                    end
                end

                if (out_read_pending_q) begin
                    if (!out_main_valid_tmp) begin
                        out_main_data_tmp  = out_return_data;
                        out_main_valid_tmp = 1'b1;
                    end else if (!out_prefetch_valid_tmp) begin
                        out_prefetch_data_tmp  = out_return_data;
                        out_prefetch_valid_tmp = 1'b1;
                    end
                end

                out_main_data_d      = out_main_data_tmp;
                out_main_valid_d     = out_main_valid_tmp;
                out_prefetch_data_d  = out_prefetch_data_tmp;
                out_prefetch_valid_d = out_prefetch_valid_tmp;

                if ((out_issue_count_q < FFT_N) && !(out_main_valid_tmp && out_prefetch_valid_tmp)) begin
                    bank0_re_b          = 1'b1;
                    bank0_addr_b        = out_issue_addr;
                    bank1_re_b          = 1'b1;
                    bank1_addr_b        = out_issue_addr;
                    out_pending_index_d = out_issue_index;
                    out_read_pending_d  = 1'b1;
                    out_issue_count_d   = out_issue_count_q + 1'b1;
                end

                if (send_fire && (out_sent_count_q == LAST_INDEX)) begin
                    out_issue_count_d    = '0;
                    out_sent_count_d     = '0;
                    out_read_pending_d   = 1'b0;
                    out_pending_index_d  = '0;
                    out_main_valid_d     = 1'b0;
                    out_main_data_d      = '0;
                    out_prefetch_valid_d = 1'b0;
                    out_prefetch_data_d  = '0;
                    state_d              = ST_CAPTURE;
                end
            end

            default: begin
                state_d = ST_CAPTURE;
            end
        endcase
    end

endmodule
