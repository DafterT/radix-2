#include "model_double.h"

#include <stdio.h>
#include <stdlib.h>

static double random_noise_sample(void) {
    return -1.0 + (2.0 * (double)rand() / (double)RAND_MAX);
}

static void fill_noise_signal(fft64_complex_t signal[FFT64_SIZE]) {
    for (int i = 0; i < FFT64_SIZE; ++i) {
        signal[i].re = random_noise_sample();
        signal[i].im = random_noise_sample();
    }
}

static void print_complex_vector(const char *title, const fft64_complex_t data[FFT64_SIZE]) {
    printf("%s\n", title);

    for (int i = 0; i < FFT64_SIZE; ++i) {
        printf("[%2d] % .6f %+.6fj\n", i, data[i].re, data[i].im);
    }
}

int main(void) {
    fft64_complex_t input_signal[FFT64_SIZE];
    fft64_result_t fft_result;

    srand(1);

    fill_noise_signal(input_signal);
    fft_result = fft64_radix2(input_signal);

    print_complex_vector("Input noise in range [-1, 1]:", input_signal);
    print_complex_vector("FFT result:", fft_result.bins);

    return 0;
}
