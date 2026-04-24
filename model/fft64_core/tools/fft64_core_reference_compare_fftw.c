#include "../reference/fft64_core_reference_model.h"

#include <fftw3.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

static double random_noise_sample(void) {
    return -1.0 + (2.0 * (double)rand() / (double)RAND_MAX);
}

static void fill_noise_signal(fft64_core_complex_t signal[FFT64_CORE_SIZE]) {
    for (int i = 0; i < FFT64_CORE_SIZE; ++i) {
        signal[i].re = random_noise_sample();
        signal[i].im = random_noise_sample();
    }
}

static void copy_to_fftw_input(
    const fft64_core_complex_t input_signal[FFT64_CORE_SIZE],
    fftw_complex fftw_input[FFT64_CORE_SIZE]
) {
    for (int i = 0; i < FFT64_CORE_SIZE; ++i) {
        fftw_input[i][0] = input_signal[i].re;
        fftw_input[i][1] = input_signal[i].im;
    }
}

int main(void) {
    fft64_core_complex_t input_signal[FFT64_CORE_SIZE];
    fft64_core_result_t my_result;
    fftw_complex fftw_input[FFT64_CORE_SIZE];
    fftw_complex fftw_output[FFT64_CORE_SIZE];
    fftw_plan fftw_forward_plan;
    double max_delta_mag = 0.0;
    double sum_delta_mag = 0.0;

    srand(1);
    fill_noise_signal(input_signal);

    my_result = fft64_core_reference_eval(input_signal);
    copy_to_fftw_input(input_signal, fftw_input);

    fftw_forward_plan = fftw_plan_dft_1d(
        FFT64_CORE_SIZE,
        fftw_input,
        fftw_output,
        FFTW_FORWARD,
        FFTW_ESTIMATE
    );

    if (fftw_forward_plan == NULL) {
        fprintf(stderr, "Failed to create FFTW plan.\n");
        return 1;
    }

    fftw_execute(fftw_forward_plan);

    printf("Comparing fft64_core_reference_model.c against FFTW3\n");
    printf("Input: deterministic complex white noise, FFT64_CORE_SIZE=%d, srand(1)\n\n", FFT64_CORE_SIZE);
    printf(
        "%3s | %24s | %24s | %12s | %12s | %12s\n",
        "bin",
        "mine (re, im)",
        "fftw (re, im)",
        "delta_re",
        "delta_im",
        "|delta|"
    );

    for (int i = 0; i < FFT64_CORE_SIZE; ++i) {
        double delta_re = my_result.bins[i].re - fftw_output[i][0];
        double delta_im = my_result.bins[i].im - fftw_output[i][1];
        double delta_mag = hypot(delta_re, delta_im);

        if (delta_mag > max_delta_mag) {
            max_delta_mag = delta_mag;
        }

        sum_delta_mag += delta_mag;

        printf(
            "%3d | % .9f % .9f | % .9f % .9f | % .6e | % .6e | % .6e\n",
            i,
            my_result.bins[i].re,
            my_result.bins[i].im,
            fftw_output[i][0],
            fftw_output[i][1],
            delta_re,
            delta_im,
            delta_mag
        );
    }

    printf("\nSummary\n");
    printf("max |delta| = %.12e\n", max_delta_mag);
    printf("avg |delta| = %.12e\n", sum_delta_mag / (double)FFT64_CORE_SIZE);

    fftw_destroy_plan(fftw_forward_plan);

    return 0;
}
