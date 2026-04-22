#include "complex_mul_3dsp_model.h"

static int64_t complex_mul_3dsp_wrap_signed(int64_t value, int width) {
    uint64_t mask = (UINT64_C(1) << width) - 1U;
    uint64_t wrapped = (uint64_t)value & mask;
    uint64_t sign_bit = UINT64_C(1) << (width - 1);

    if ((wrapped & sign_bit) != 0U) {
        wrapped |= ~mask;
    }

    return (int64_t)wrapped;
}

void complex_mul_3dsp_eval(
    int16_t x_re,
    int16_t x_im,
    int16_t y_re,
    int16_t y_im,
    int64_t *out_re,
    int64_t *out_im
) {
    int64_t ar_br = (int64_t)x_re * (int64_t)y_re;
    int64_t ai_bi = (int64_t)x_im * (int64_t)y_im;
    int64_t ar_bi = (int64_t)x_re * (int64_t)y_im;
    int64_t ai_br = (int64_t)x_im * (int64_t)y_re;

    *out_re = complex_mul_3dsp_wrap_signed(ar_br - ai_bi, 33);
    *out_im = complex_mul_3dsp_wrap_signed(ar_bi + ai_br, 33);
}
