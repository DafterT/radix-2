#ifndef FFT64_BUTTERFLY_FIXED_H
#define FFT64_BUTTERFLY_FIXED_H

#include "model_fixed.h"

void fft64_fixed_butterfly(
    fft64_fixed_cpx_q16_0_t *top,
    fft64_fixed_cpx_q16_0_t *bottom,
    int twiddle_index
);

#endif
