#ifndef FFT64_CORE_FIXED_DIV2_BUTTERFLY_H
#define FFT64_CORE_FIXED_DIV2_BUTTERFLY_H

#include "fft64_core_fixed_div2_model.h"

void fft64_core_fixed_div2_butterfly(
    fft64_core_cpx_q16_0_t *top,
    fft64_core_cpx_q16_0_t *bottom,
    int twiddle_index,
    int apply_div2
);

#endif
