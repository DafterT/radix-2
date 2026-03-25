#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define FFT_SIZE 64
#define TWIDDLE_COUNT (FFT_SIZE / 2)
#define PI 3.14159265358979323846

typedef struct {
    double re;
    double im;
} fft_complex_t;

typedef struct {
    fft_complex_t bins[FFT_SIZE];
} fft64_result_t;

static fft_complex_t complex_mul(fft_complex_t a, fft_complex_t b) {
    fft_complex_t result;

    result.re = (a.re * b.re) - (a.im * b.im);
    result.im = (a.re * b.im) + (a.im * b.re);

    return result;
}

static void fft64_compute_twiddles(fft_complex_t twiddles[TWIDDLE_COUNT]) {
    for (int k = 0; k < TWIDDLE_COUNT; ++k) {
        double angle = 2.0 * PI * (double)k / (double)FFT_SIZE;

        twiddles[k].re =  cos(angle);
        twiddles[k].im = -sin(angle);
    }
}

static void fft64_butterfly(fft_complex_t *top, fft_complex_t *bottom, fft_complex_t twiddle) {
    fft_complex_t top_value = *top;
    fft_complex_t bottom_value = *bottom;
    fft_complex_t product = complex_mul(bottom_value, twiddle);

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
    const fft_complex_t input[FFT_SIZE],
    fft_complex_t output[FFT_SIZE]
) {
    for (unsigned i = 0; i < FFT_SIZE; ++i) {
        output[reverse_bits_6(i)] = input[i];
    }
}

static void fft64_execute_stage(
    fft_complex_t data[FFT_SIZE],
    const fft_complex_t twiddles[TWIDDLE_COUNT],
    int stage_size
) {
    int half_stage = stage_size / 2;
    int twiddle_step = FFT_SIZE / stage_size;

    for (int block_start = 0; block_start < FFT_SIZE; block_start += stage_size) {
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
    fft_complex_t data[FFT_SIZE],
    const fft_complex_t twiddles[TWIDDLE_COUNT]
) {
    for (int stage_size = 2; stage_size <= FFT_SIZE; stage_size *= 2) {
        fft64_execute_stage(data, twiddles, stage_size);
    }
}

fft64_result_t fft64_radix2(const fft_complex_t input[FFT_SIZE]) {
    fft64_result_t result;
    fft_complex_t twiddles[TWIDDLE_COUNT];

    fft64_compute_twiddles(twiddles);
    fft64_bit_reverse_copy(input, result.bins);
    fft64_execute_all_stages(result.bins, twiddles);

    return result;
}

static double random_noise_sample(void) {
    return -1.0 + (2.0 * (double)rand() / (double)RAND_MAX);
}

static void fill_noise_signal(fft_complex_t signal[FFT_SIZE]) {
    for (int i = 0; i < FFT_SIZE; ++i) {
        signal[i].re = random_noise_sample();
        signal[i].im = random_noise_sample();
    }
}

static void print_complex_vector(const char *title, const fft_complex_t data[FFT_SIZE]) {
    printf("%s\n", title);

    for (int i = 0; i < FFT_SIZE; ++i) {
        printf("[%2d] % .6f %+.6fj\n", i, data[i].re, data[i].im);
    }
}

static void test_fft64_noise(void) {
    fft_complex_t input_signal[FFT_SIZE];
    fft64_result_t fft_result;

    srand(1);

    fill_noise_signal(input_signal);
    fft_result = fft64_radix2(input_signal);

    print_complex_vector("Input noise in range [-1, 1]:", input_signal);
    print_complex_vector("FFT result:", fft_result.bins);
}

int main(void) {
    test_fft64_noise();
    return 0;
}
