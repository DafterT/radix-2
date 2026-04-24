#ifndef FFT64_CORE_FIXED_COLLECT_BUTTERFLY_H
#define FFT64_CORE_FIXED_COLLECT_BUTTERFLY_H

#include "fft64_core_fixed_collect_model.h"

void fft64_core_fixed_collect_butterfly(
    fft64_core_cpx_q22_0_t *top,
    fft64_core_cpx_q22_0_t *bottom,
    int twiddle_index
);

#endif
