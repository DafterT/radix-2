#ifndef FFT64_FIXED_BUTTERFLY_H
#define FFT64_FIXED_BUTTERFLY_H

#include "fft64_model_fixed.h"

void fft64_fixed_butterfly(
    fft64_fixed_cpx_q16_0_t *top,
    fft64_fixed_cpx_q16_0_t *bottom,
    int twiddle_index
);

#endif
