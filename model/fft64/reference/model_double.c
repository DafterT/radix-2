#include "model_double.h"

#include <math.h>

#define PI 3.14159265358979323846

static fft64_complex_t complex_mul(fft64_complex_t a, fft64_complex_t b) {
    fft64_complex_t result;

    result.re = (a.re * b.re) - (a.im * b.im);
    result.im = (a.re * b.im) + (a.im * b.re);

    return result;
}

static void fft64_compute_twiddles(fft64_complex_t twiddles[FFT64_TWIDDLE_COUNT]) {
    for (int k = 0; k < FFT64_TWIDDLE_COUNT; ++k) {
        double angle = 2.0 * PI * (double)k / (double)FFT64_SIZE;

        twiddles[k].re = cos(angle);
        twiddles[k].im = -sin(angle);
    }
}

static void fft64_butterfly(
    fft64_complex_t *top,
    fft64_complex_t *bottom,
    fft64_complex_t twiddle
) {
    fft64_complex_t top_value = *top;
    fft64_complex_t bottom_value = *bottom;
    fft64_complex_t product = complex_mul(bottom_value, twiddle);

    top->re = top_value.re + product.re;
    top->im = top_value.im + product.im;

    bottom->re = top_value.re - product.re;
    bottom->im = top_value.im - product.im;
}

static unsigned reverse_bits_6(unsigned value) {
    unsigned reversed = 0;

    for (int bit = 0; bit < 6; ++bit) {
        reversed = (reversed << 1U) | ((value >> bit) & 1U);
    }

    return reversed;
}

static void fft64_bit_reverse_copy(
    const fft64_complex_t input[FFT64_SIZE],
    fft64_complex_t output[FFT64_SIZE]
) {
    for (unsigned i = 0; i < FFT64_SIZE; ++i) {
        output[reverse_bits_6(i)] = input[i];
    }
}

static void fft64_execute_stage(
    fft64_complex_t data[FFT64_SIZE],
    const fft64_complex_t twiddles[FFT64_TWIDDLE_COUNT],
    int stage_size
) {
    int half_stage = stage_size / 2;
    int twiddle_step = FFT64_SIZE / stage_size;

    for (int block_start = 0; block_start < FFT64_SIZE; block_start += stage_size) {
        for (int j = 0; j < half_stage; ++j) {
            int top_index = block_start + j;
            int bottom_index = top_index + half_stage;
            int twiddle_index = j * twiddle_step;

            fft64_butterfly(
                &data[top_index],
                &data[bottom_index],
                twiddles[twiddle_index]
            );
        }
    }
}

static void fft64_execute_all_stages(
    fft64_complex_t data[FFT64_SIZE],
    const fft64_complex_t twiddles[FFT64_TWIDDLE_COUNT]
) {
    for (int stage_size = 2; stage_size <= FFT64_SIZE; stage_size *= 2) {
        fft64_execute_stage(data, twiddles, stage_size);
    }
}

fft64_result_t fft64_radix2(const fft64_complex_t input[FFT64_SIZE]) {
    fft64_result_t result;
    fft64_complex_t twiddles[FFT64_TWIDDLE_COUNT];

    fft64_compute_twiddles(twiddles);
    fft64_bit_reverse_copy(input, result.bins);
    fft64_execute_all_stages(result.bins, twiddles);

    return result;
}
