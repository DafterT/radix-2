#ifndef FFT64_BUTTERFLY_FIXED_H
#define FFT64_BUTTERFLY_FIXED_H

#include "model_fixed.h"

void fft64_fixed_butterfly_div2(
    fft64_fixed_cpx_q16_0_t *top,
    fft64_fixed_cpx_q16_0_t *bottom,
    int twiddle_index,
    int apply_div2
);

#endif
