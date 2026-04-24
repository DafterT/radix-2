#ifndef FFT64_CORE_WHITE_NOISE_H
#define FFT64_CORE_WHITE_NOISE_H

#include <stdint.h>

#include "../fft64_core_model_types.h"

#define FFT64_WHITE_NOISE_DEFAULT_BACKOFF_DB 12.0

double fft64_core_white_noise_input_scale(double backoff_db);

void fft64_core_white_noise_generate_frame(
    fft64_core_cpx_q16_0_t output[FFT64_CORE_SIZE],
    uint32_t base_seed,
    uint32_t frame_index,
    double backoff_db
);

#endif
