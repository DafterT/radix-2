#ifndef WHITE_NOISE_BACKOFF_DB
#define WHITE_NOISE_BACKOFF_DB 11.0
#endif

#ifndef FFT64_COMPARE_RUNS
#define FFT64_COMPARE_RUNS 100
#endif

#include "../fixed/model_fixed.h"
#include "../reference/model_double.h"

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define INPUT_WIDTH 16

static double compare_random_unit_sample(void) {
    return -1.0 + (2.0 * (double)rand() / (double)RAND_MAX);
}

static int16_t compare_round_clip_q16_0(double value_q16_0) {
    const long max_q16_0 = (1L << (INPUT_WIDTH - 1)) - 1L;
    const long min_q16_0 = -(1L << (INPUT_WIDTH - 1));
    long rounded = lround(value_q16_0);

    if (rounded > max_q16_0) {
        rounded = max_q16_0;
    }

    if (rounded < min_q16_0) {
        rounded = min_q16_0;
    }

    return (int16_t)rounded;
}

static fft64_fixed_cpx_q16_0_t compare_make_fixed_input(double input_scale) {
    fft64_fixed_cpx_q16_0_t sample;

    sample.re = compare_round_clip_q16_0(compare_random_unit_sample() * input_scale);
    sample.im = compare_round_clip_q16_0(compare_random_unit_sample() * input_scale);

    return sample;
}

static fft64_complex_t compare_fixed_to_double(fft64_fixed_cpx_q16_0_t value) {
    fft64_complex_t result;

    result.re = (double)value.re;
    result.im = (double)value.im;

    return result;
}

static double compare_reference_output_scale(void) {
    double scale = 1.0;

    for (int stage_size = 2; stage_size <= FFT64_SIZE; stage_size *= 2) {
        scale *= 1.0 / sqrt(2.0);
    }

    return scale;
}

static double compare_cpx_error_mag(fft64_complex_t reference, fft64_complex_t actual) {
    return hypot(reference.re - actual.re, reference.im - actual.im);
}

static double compare_cpx_power(fft64_complex_t value) {
    return (value.re * value.re) + (value.im * value.im);
}

static double compare_sqnr_db(double signal_power, double noise_power) {
    if (noise_power <= 0.0) {
        return INFINITY;
    }

    return 10.0 * log10(signal_power / noise_power);
}

int main(void) {
    const double max_q16_0 = (double)((1L << (INPUT_WIDTH - 1)) - 1L);
    const double fullscale_power = 2.0 * max_q16_0 * max_q16_0;
    const double backoff_ratio = pow(10.0, WHITE_NOISE_BACKOFF_DB / 10.0);
    const double input_scale = sqrt(fullscale_power / backoff_ratio);
    const double reference_output_scale = compare_reference_output_scale();
    double sqnr_sum_db = 0.0;
    double total_error_mag = 0.0;
    double max_error_mag = 0.0;

    srand(1);

    printf("FFT64 size         = %d\n", FFT64_FIXED_SIZE);
    printf("Runs               = %d\n", FFT64_COMPARE_RUNS);
    printf("Bins per run       = %d\n", FFT64_FIXED_SIZE);
    printf("Total bins         = %d\n", FFT64_COMPARE_RUNS * FFT64_FIXED_SIZE);
    printf("Backoff            = %.3f dB\n", WHITE_NOISE_BACKOFF_DB);
    printf("Input scale        = %.3f\n", input_scale);
    printf("Reference scale    = %.9f\n\n", reference_output_scale);

    for (int run = 0; run < FFT64_COMPARE_RUNS; ++run) {
        fft64_fixed_cpx_q16_0_t fixed_input[FFT64_FIXED_SIZE];
        fft64_complex_t reference_input[FFT64_SIZE];
        fft64_fixed_result_t fixed_output;
        fft64_result_t reference_output;
        double run_error_mag = 0.0;
        double run_max_error_mag = 0.0;
        double signal_power = 0.0;
        double noise_power = 0.0;

        for (int i = 0; i < FFT64_FIXED_SIZE; ++i) {
            fixed_input[i] = compare_make_fixed_input(input_scale);
            reference_input[i] = compare_fixed_to_double(fixed_input[i]);
        }

        fixed_output = fft64_radix2_fixed(fixed_input);
        reference_output = fft64_radix2(reference_input);

        for (int bin = 0; bin < FFT64_FIXED_SIZE; ++bin) {
            fft64_complex_t fixed_bin = compare_fixed_to_double(fixed_output.bins[bin]);
            fft64_complex_t reference_bin = {
                .re = reference_output.bins[bin].re * reference_output_scale,
                .im = reference_output.bins[bin].im * reference_output_scale
            };
            double error_mag = compare_cpx_error_mag(reference_bin, fixed_bin);
            fft64_complex_t error_bin = {
                .re = reference_bin.re - fixed_bin.re,
                .im = reference_bin.im - fixed_bin.im
            };

            run_error_mag += error_mag;
            total_error_mag += error_mag;
            signal_power += compare_cpx_power(reference_bin);
            noise_power += compare_cpx_power(error_bin);

            if (error_mag > run_max_error_mag) {
                run_max_error_mag = error_mag;
            }

            if (error_mag > max_error_mag) {
                max_error_mag = error_mag;
            }
        }
        double run_sqnr_db = compare_sqnr_db(signal_power, noise_power);

        sqnr_sum_db += run_sqnr_db;

        printf(
            "run=%d avg_error=%.6f max_error=%.6f signal_power=%.3f noise_power=%.3f sqnr=%.3f dB\n",
            run,
            run_error_mag / (double)FFT64_FIXED_SIZE,
            run_max_error_mag,
            signal_power,
            noise_power,
            run_sqnr_db
        );
    }

    printf("\nAverage error      = %.6f\n", total_error_mag / (double)(FFT64_COMPARE_RUNS * FFT64_FIXED_SIZE));
    printf("Maximum error      = %.6f\n", max_error_mag);
    printf("Average SQNR       = %.3f dB\n", sqnr_sum_db / (double)FFT64_COMPARE_RUNS);

    return 0;
}
