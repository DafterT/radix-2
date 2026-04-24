#include "fft64_core_white_noise.h"

#include <math.h>
#include <stdlib.h>

#define FFT64_WHITE_NOISE_INPUT_WIDTH 16

static double fft64_core_white_noise_random_unit_sample(void) {
    return -1.0 + (2.0 * (double)rand() / (double)RAND_MAX);
}

static int16_t fft64_core_white_noise_round_clip_q16_0(double value_q16_0) {
    const long max_q16_0 = (1L << (FFT64_WHITE_NOISE_INPUT_WIDTH - 1)) - 1L;
    const long min_q16_0 = -(1L << (FFT64_WHITE_NOISE_INPUT_WIDTH - 1));
    long rounded = lround(value_q16_0);

    if (rounded > max_q16_0) {
        rounded = max_q16_0;
    }

    if (rounded < min_q16_0) {
        rounded = min_q16_0;
    }

    return (int16_t)rounded;
}

double fft64_core_white_noise_input_scale(double backoff_db) {
    const double max_q16_0 = (double)((1L << (FFT64_WHITE_NOISE_INPUT_WIDTH - 1)) - 1L);
    const double fullscale_power = 2.0 * max_q16_0 * max_q16_0;
    const double backoff_ratio = pow(10.0, backoff_db / 10.0);

    return sqrt(fullscale_power / backoff_ratio);
}

void fft64_core_white_noise_generate_frame(
    fft64_core_cpx_q16_0_t output[FFT64_CORE_SIZE],
    uint32_t base_seed,
    uint32_t frame_index,
    double backoff_db
) {
    const double input_scale = fft64_core_white_noise_input_scale(backoff_db);

    srand((unsigned)(base_seed + frame_index));

    for (int i = 0; i < FFT64_CORE_SIZE; ++i) {
        output[i].re = fft64_core_white_noise_round_clip_q16_0(
            fft64_core_white_noise_random_unit_sample() * input_scale
        );
        output[i].im = fft64_core_white_noise_round_clip_q16_0(
            fft64_core_white_noise_random_unit_sample() * input_scale
        );
    }
}
