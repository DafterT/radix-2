#ifndef FFT64_CORE_REFERENCE_MODEL_H
#define FFT64_CORE_REFERENCE_MODEL_H

#include "../fft64_core_model_types.h"

fft64_core_result_t fft64_core_reference_eval(
    const fft64_core_complex_t input[FFT64_CORE_SIZE]
);

#endif
