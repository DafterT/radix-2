#include "butterfly_fixed.h"

#include <math.h>
#include <stdint.h>

#define PI 3.14159265358979323846
#define FFT64_FIXED_TWIDDLE_COUNT (FFT64_FIXED_SIZE / 2)

typedef struct {
    int16_t re;
    int16_t im;
} fft64_fixed_cpx_q2_14_t;

typedef struct {
    int64_t re;
    int64_t im;
} fft64_fixed_cpx_i64_t;

static int64_t fft64_fixed_wrap_signed(int64_t value, int width) {
    uint64_t mask = (UINT64_C(1) << width) - 1U;
    uint64_t wrapped = (uint64_t)value & mask;
    uint64_t sign_bit = UINT64_C(1) << (width - 1);

    if ((wrapped & sign_bit) != 0U) {
        wrapped |= ~mask;
    }

    return (int64_t)wrapped;
}

static const fft64_fixed_cpx_q2_14_t *fft64_fixed_get_twiddles(void) {
    static int initialized = 0;
    static fft64_fixed_cpx_q2_14_t twiddles[FFT64_FIXED_TWIDDLE_COUNT];

    if (!initialized) {
        for (int k = 0; k < FFT64_FIXED_TWIDDLE_COUNT; ++k) {
            double angle = 2.0 * PI * (double)k / (double)FFT64_FIXED_SIZE;

            twiddles[k].re = (int16_t)fft64_fixed_wrap_signed(
                (int64_t)lround(cos(angle) * (double)(1 << 14)),
                16
            );
            twiddles[k].im = (int16_t)fft64_fixed_wrap_signed(
                (int64_t)lround(-sin(angle) * (double)(1 << 14)),
                16
            );
        }

        initialized = 1;
    }

    return twiddles;
}

static fft64_fixed_cpx_i64_t fft64_fixed_complex_mul_q22_0_q2_14(
    fft64_fixed_cpx_q22_0_t x_q22_0,
    fft64_fixed_cpx_q2_14_t y_q2_14
) {
    return (fft64_fixed_cpx_i64_t){
        .re = ((int64_t)x_q22_0.re * (int64_t)y_q2_14.re) -
              ((int64_t)x_q22_0.im * (int64_t)y_q2_14.im),
        .im = ((int64_t)x_q22_0.re * (int64_t)y_q2_14.im) +
              ((int64_t)x_q22_0.im * (int64_t)y_q2_14.re)
    };
}

static int32_t fft64_fixed_round_wrap_q22_14_to_q22_0(int64_t value_q22_14) {
    int64_t rounded_q22_0 = value_q22_14 >> 14;
    int64_t frac_q22_14 = value_q22_14 & ((INT64_C(1) << 14) - 1);
    int round_up = 0;

    if (frac_q22_14 > (INT64_C(1) << 13)) {
        round_up = 1;
    }

    if ((frac_q22_14 == (INT64_C(1) << 13)) && ((rounded_q22_0 & 1) != 0)) {
        round_up = 1;
    }

    if (round_up) {
        rounded_q22_0 += 1;
    }

    return (int32_t)fft64_fixed_wrap_signed(rounded_q22_0, 22);
}

void fft64_fixed_butterfly_collect(
    fft64_fixed_cpx_q22_0_t *top,
    fft64_fixed_cpx_q22_0_t *bottom,
    int twiddle_index
) {
    const fft64_fixed_cpx_q2_14_t *twiddles = fft64_fixed_get_twiddles();
    fft64_fixed_cpx_q2_14_t twiddle_q2_14 = twiddles[twiddle_index];
    fft64_fixed_cpx_i64_t bw_q22_14 = fft64_fixed_complex_mul_q22_0_q2_14(*bottom, twiddle_q2_14);
    fft64_fixed_cpx_i64_t a_q22_14 = {
        .re = (int64_t)top->re << 14,
        .im = (int64_t)top->im << 14
    };
    fft64_fixed_cpx_i64_t sum_q22_14 = {
        .re = a_q22_14.re + bw_q22_14.re,
        .im = a_q22_14.im + bw_q22_14.im
    };
    fft64_fixed_cpx_i64_t diff_q22_14 = {
        .re = a_q22_14.re - bw_q22_14.re,
        .im = a_q22_14.im - bw_q22_14.im
    };

    top->re = fft64_fixed_round_wrap_q22_14_to_q22_0(sum_q22_14.re);
    top->im = fft64_fixed_round_wrap_q22_14_to_q22_0(sum_q22_14.im);
    bottom->re = fft64_fixed_round_wrap_q22_14_to_q22_0(diff_q22_14.re);
    bottom->im = fft64_fixed_round_wrap_q22_14_to_q22_0(diff_q22_14.im);
}
