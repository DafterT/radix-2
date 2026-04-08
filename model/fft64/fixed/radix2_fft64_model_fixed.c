#include "fft64_model_fixed.h"
#include "fft64_fixed_butterfly.h"

static unsigned reverse_bits_6(unsigned value) {
    unsigned reversed = 0;

    for (int bit = 0; bit < 6; ++bit) {
        reversed = (reversed << 1U) | ((value >> bit) & 1U);
    }

    return reversed;
}

static void fft64_fixed_bit_reverse_copy(
    const fft64_fixed_cpx_q16_0_t input[FFT64_FIXED_SIZE],
    fft64_fixed_cpx_q16_0_t output[FFT64_FIXED_SIZE]
) {
    for (unsigned i = 0; i < FFT64_FIXED_SIZE; ++i) {
        output[reverse_bits_6(i)] = input[i];
    }
}

static void fft64_fixed_execute_stage(
    fft64_fixed_cpx_q16_0_t data[FFT64_FIXED_SIZE],
    int stage_size
) {
    int half_stage = stage_size / 2;
    int twiddle_step = FFT64_FIXED_SIZE / stage_size;

    for (int block_start = 0; block_start < FFT64_FIXED_SIZE; block_start += stage_size) {
        for (int j = 0; j < half_stage; ++j) {
            int top_index = block_start + j;
            int bottom_index = top_index + half_stage;
            int twiddle_index = j * twiddle_step;

            fft64_fixed_butterfly(
                &data[top_index],
                &data[bottom_index],
                twiddle_index
            );
        }
    }
}

static void fft64_fixed_execute_all_stages(
    fft64_fixed_cpx_q16_0_t data[FFT64_FIXED_SIZE]
) {
    for (int stage_size = 2; stage_size <= FFT64_FIXED_SIZE; stage_size *= 2) {
        fft64_fixed_execute_stage(data, stage_size);
    }
}

fft64_fixed_result_t fft64_radix2_fixed(
    const fft64_fixed_cpx_q16_0_t input[FFT64_FIXED_SIZE]
) {
    fft64_fixed_result_t result;

    fft64_fixed_bit_reverse_copy(input, result.bins);
    fft64_fixed_execute_all_stages(result.bins);

    return result;
}
