#include "dsp48e2_like_model.h"

static int64_t dsp48e2_like_wrap_signed(int64_t value, int width) {
    uint64_t mask = (UINT64_C(1) << width) - 1U;
    uint64_t wrapped = (uint64_t)value & mask;
    uint64_t sign_bit = UINT64_C(1) << (width - 1);

    if ((wrapped & sign_bit) != 0U) {
        wrapped |= ~mask;
    }

    return (int64_t)wrapped;
}

int64_t dsp48e2_like_eval(
    int preadd_sub,
    int postadd_en,
    int postadd_sub,
    int32_t a_in,
    int32_t d_in,
    int32_t b_in,
    int64_t c_in
) {
    int32_t a_30 = (int32_t)dsp48e2_like_wrap_signed((int64_t)a_in, 30);
    int32_t d_27 = (int32_t)dsp48e2_like_wrap_signed((int64_t)d_in, 27);
    int32_t b_18 = (int32_t)dsp48e2_like_wrap_signed((int64_t)b_in, 18);
    int64_t c_48 = dsp48e2_like_wrap_signed(c_in, 48);

    /* RTL uses only A[26:0] inside the pre-adder. */
    int32_t a_27 = (int32_t)dsp48e2_like_wrap_signed((int64_t)a_30, 27);
    int32_t pre_q;
    int64_t m_q;
    int64_t m_p;

    if (preadd_sub != 0) {
        pre_q = (int32_t)dsp48e2_like_wrap_signed((int64_t)d_27 - (int64_t)a_27, 27);
    } else {
        pre_q = (int32_t)dsp48e2_like_wrap_signed((int64_t)d_27 + (int64_t)a_27, 27);
    }

    m_q = dsp48e2_like_wrap_signed((int64_t)pre_q * (int64_t)b_18, 45);
    m_p = dsp48e2_like_wrap_signed(m_q, 48);

    if (postadd_en == 0) {
        return dsp48e2_like_wrap_signed(m_p, 48);
    }

    if (postadd_sub != 0) {
        return dsp48e2_like_wrap_signed(c_48 - m_p, 48);
    }

    return dsp48e2_like_wrap_signed(c_48 + m_p, 48);
}
