#include "butterfly_fixed.h"

#include <math.h>
#include <stdint.h>

#define PI 3.14159265358979323846
#define FFT64_FIXED_TWIDDLE_COUNT (FFT64_FIXED_SIZE / 2)

// INV_SQRT2_Q1_17 = $rtoi((1 / sqrt(2)) * 2^17)
#define INV_SQRT2_Q1_17 ((int64_t)92681)

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

static fft64_fixed_cpx_i64_t fft64_fixed_complex_mul_q16_0_q2_14(
    fft64_fixed_cpx_q16_0_t x_q16_0,
    fft64_fixed_cpx_q2_14_t y_q2_14
) {
    return (fft64_fixed_cpx_i64_t){
        .re = fft64_fixed_wrap_signed(
            ((int64_t)x_q16_0.re * (int64_t)y_q2_14.re) -
            ((int64_t)x_q16_0.im * (int64_t)y_q2_14.im),
            33
        ),
        .im = fft64_fixed_wrap_signed(
            ((int64_t)x_q16_0.re * (int64_t)y_q2_14.im) +
            ((int64_t)x_q16_0.im * (int64_t)y_q2_14.re),
            33
        )
    };
}

static int16_t fft64_fixed_round_clip_q22_23_to_q16_0(int64_t value_q22_23) {
    value_q22_23 = fft64_fixed_wrap_signed(value_q22_23, 45);

    int64_t rounded_q22_0 = value_q22_23 >> 23;
    int64_t frac_q22_23 = value_q22_23 & ((INT64_C(1) << 23) - 1);
    int round_up = 0;

    if (frac_q22_23 > (INT64_C(1) << 22)) {
        round_up = 1;
    }

    if ((frac_q22_23 == (INT64_C(1) << 22)) && ((rounded_q22_0 & 1) != 0)) {
        round_up = 1;
    }

    if (round_up) {
        rounded_q22_0 += 1;
    }

    {
        const int64_t max_q16_0 = ((int64_t)1 << 15) - 1;
        const int64_t min_q16_0 = -max_q16_0;

        if (rounded_q22_0 > max_q16_0) {
            return (int16_t)max_q16_0;
        }

        if (rounded_q22_0 < min_q16_0) {
            return (int16_t)min_q16_0;
        }
    }

    return (int16_t)rounded_q22_0;
}

void fft64_fixed_butterfly(
    fft64_fixed_cpx_q16_0_t *top,
    fft64_fixed_cpx_q16_0_t *bottom,
    int twiddle_index
) {
    const fft64_fixed_cpx_q2_14_t *twiddles = fft64_fixed_get_twiddles();
    fft64_fixed_cpx_q2_14_t twiddle_q2_14 = twiddles[twiddle_index];
    fft64_fixed_cpx_i64_t bw_q19_14 = fft64_fixed_complex_mul_q16_0_q2_14(*bottom, twiddle_q2_14);
    fft64_fixed_cpx_i64_t a_q20_14 = {
        .re = (int64_t)top->re << 14,
        .im = (int64_t)top->im << 14
    };
    fft64_fixed_cpx_i64_t a_q20_6 = {
        .re = fft64_fixed_wrap_signed(a_q20_14.re >> 8, 26),
        .im = fft64_fixed_wrap_signed(a_q20_14.im >> 8, 26)
    };
    fft64_fixed_cpx_i64_t bw_q20_6 = {
        .re = fft64_fixed_wrap_signed(bw_q19_14.re >> 8, 26),
        .im = fft64_fixed_wrap_signed(bw_q19_14.im >> 8, 26)
    };
    fft64_fixed_cpx_i64_t sum_q21_6 = {
        .re = a_q20_6.re + bw_q20_6.re,
        .im = a_q20_6.im + bw_q20_6.im
    };
    fft64_fixed_cpx_i64_t diff_q21_6 = {
        .re = a_q20_6.re - bw_q20_6.re,
        .im = a_q20_6.im - bw_q20_6.im
    };
    fft64_fixed_cpx_i64_t top_out_q22_23 = {
        .re = sum_q21_6.re * INV_SQRT2_Q1_17,
        .im = sum_q21_6.im * INV_SQRT2_Q1_17
    };
    fft64_fixed_cpx_i64_t bottom_out_q22_23 = {
        .re = diff_q21_6.re * INV_SQRT2_Q1_17,
        .im = diff_q21_6.im * INV_SQRT2_Q1_17
    };

    top->re = fft64_fixed_round_clip_q22_23_to_q16_0(top_out_q22_23.re);
    top->im = fft64_fixed_round_clip_q22_23_to_q16_0(top_out_q22_23.im);
    bottom->re = fft64_fixed_round_clip_q22_23_to_q16_0(bottom_out_q22_23.re);
    bottom->im = fft64_fixed_round_clip_q22_23_to_q16_0(bottom_out_q22_23.im);
}
