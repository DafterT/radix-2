module DSP48E2_like #(
    // preadder: 
    //      0 => D + A 
    //      1 => D - A
    parameter bit PREADD_SUB = 1'b0,

    // postadder enable: 
    //      0 => output = Mreg 
    //      1 => output = (Mreg +- C) через регистр
    parameter bit POSTADD_EN  = 1'b0,

    // postadder:
    //      0 => +C 
    //      1 => -C
    parameter bit POSTADD_SUB = 1'b0   
) (
    input  logic                  clk,
    input  logic                  rst,

    input  logic signed [29:0]     A,   // 30-bit A port
    input  logic signed [26:0]     D,   // 27-bit D port
    input  logic signed [17:0]     B,   // 18-bit B port
    input  logic signed [47:0]     C,   // 48-bit C port

    output logic signed [47:0]     Y
);

    // ------------------------------------------------------------
    // Dual B register: B -> B1 -> B2
    // ------------------------------------------------------------
    logic signed [17:0] b1_q, b2_q;

    always_ff @(posedge clk) begin
        if (rst) begin
            b1_q <= '0;
            b2_q <= '0;
        end else begin
            b1_q <= B;
            b2_q <= b1_q;
        end
    end

    // ------------------------------------------------------------
    // Preadder
    // ------------------------------------------------------------

    // A and D registers
    logic signed [29:0] a_q;
    logic signed [26:0] d_q;

    always_ff @(posedge clk) begin
        if (rst) begin
            a_q <= '0;
            d_q <= '0;
        end else begin
            a_q <= A;
            d_q <= D;
        end
    end

    // preadder comb
    logic signed [26:0] a27;
    assign  a27 = a_q[26:0];

    logic signed [26:0] pre_comb;

    generate
        if (PREADD_SUB) begin : gen_pre_sub
            always_comb pre_comb = d_q - a27;
        end else begin : gen_pre_add
            always_comb pre_comb = d_q + a27;
        end
    endgenerate

    // preadder reg
    logic signed [26:0] pre_q;
    always_ff @(posedge clk) begin
        if (rst) pre_q <= '0;
        else     pre_q <= pre_comb;
    end

    // ------------------------------------------------------------
    // Multiply: M = pre_q * b2_q
    // ------------------------------------------------------------
    localparam int M_W = 27 + 18; // 45
    logic signed [M_W-1:0] m_comb, m_q;

    assign m_comb = pre_q * b2_q;

    always_ff @(posedge clk) begin
        if (rst) m_q <= '0;
        else     m_q <= m_comb;
    end

    // Расширение знака
    logic signed [47:0] m_p;
    assign m_p = {{(48-M_W){m_q[M_W-1]}}, m_q};

    // ------------------------------------------------------------
    // Post-adder and final output register
    // ------------------------------------------------------------
    logic signed [47:0] post_comb;

    generate
        if (POSTADD_EN) begin : gen_post
            if (POSTADD_SUB) begin : gen_post_sub
                assign post_comb = C - m_p;
            end else begin : gen_post_add
                assign post_comb = C + m_p;
            end

            // Final register
            always_ff @(posedge clk) begin
                if (rst) Y <= '0;
                else     Y <= post_comb;
            end
        end else begin : gen_no_post
            assign Y = m_p;
        end
    endgenerate

endmodule
