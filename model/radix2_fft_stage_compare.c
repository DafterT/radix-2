#ifndef FFT_N
#define FFT_N 64
#endif

#ifndef WHITE_NOISE_BACKOFF_DB
#define WHITE_NOISE_BACKOFF_DB 10.0
#endif

#include "radix2_fft_stage_model.h"
#include "radix2_fft_stage_model_double.h"

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// Convert input backoff from dB to a linear amplitude scale.
static double compare_white_noise_backoff_linear(void) {
    return pow(10.0, WHITE_NOISE_BACKOFF_DB / 20.0);
}

// Generate one local Q16.0 white-noise sample with dB backoff.
static int16_t compare_white_noise_q16_0_sample(void) {
    double normalized_noise = -1.0 + (2.0 * (double)rand() / (double)RAND_MAX);
    double backed_off_noise = normalized_noise / compare_white_noise_backoff_linear();
    long quantized = lround(backed_off_noise * (double)INT16_MAX);

    if (quantized > INT16_MAX) {
        quantized = INT16_MAX;
    }

    if (quantized < -INT16_MAX) {
        quantized = -INT16_MAX;
    }

    return (int16_t)quantized;
}

// Fill one local frame of fixed-point white-noise samples for comparison.
static void compare_fill_white_noise_signal(fixed_stage_cpx_q16_0_t signal[FFT_N]) {
    for (int i = 0; i < FFT_N; ++i) {
        signal[i].re = compare_white_noise_q16_0_sample();
        signal[i].im = compare_white_noise_q16_0_sample();
    }
}

static double_stage_cpx_t compare_q16_input_to_double(fixed_stage_cpx_q16_0_t value) {
    double_stage_cpx_t result;

    result.re = (double)value.re;
    result.im = (double)value.im;

    return result;
}

static double compare_sqnr_db(double signal_power, double noise_power) {
    if (noise_power == 0.0) {
        return INFINITY;
    }

    return 10.0 * log10(signal_power / noise_power);
}

static double compare_cpx_power(double_stage_cpx_t value) {
    return (value.re * value.re) + (value.im * value.im);
}

static void compare_print_complex(const char *name, double_stage_cpx_t value) {
    printf("  %s: re=% .12f, im=% .12f\n", name, value.re, value.im);
}

// Run both stage models on the same local stimulus and print the difference.
static void compare_run(void) {
    fixed_stage_model_t fixed_model = {0};
    double_stage_model_t double_model = {0};
    fixed_stage_cpx_q16_0_t signal[FFT_N];
    double reference_power = 0.0;
    double error_power = 0.0;

    srand(1);
    compare_fill_white_noise_signal(signal);
    fixed_stage_init(&fixed_model);
    double_stage_init(&double_model);

    printf(
        "Stage model comparison, FFT_N=%d, backoff=%.2f dB, scale=1/%.6f\n\n",
        FFT_N,
        WHITE_NOISE_BACKOFF_DB,
        compare_white_noise_backoff_linear()
    );

    for (int pair_index = 0; pair_index < (FFT_N / 2); ++pair_index) {
        int last_i = (pair_index == ((FFT_N / 2) - 1));
        fixed_stage_cpx_q16_0_t a_fixed = signal[2 * pair_index];
        fixed_stage_cpx_q16_0_t b_fixed = signal[(2 * pair_index) + 1];
        double_stage_cpx_t a_double = compare_q16_input_to_double(a_fixed);
        double_stage_cpx_t b_double = compare_q16_input_to_double(b_fixed);
        fixed_stage_output_t fixed_output = fixed_stage_step(&fixed_model, last_i, a_fixed, b_fixed);
        double_stage_output_t reference_output = double_stage_step(&double_model, last_i, a_double, b_double);
        double_stage_cpx_t fixed_a;
        double_stage_cpx_t fixed_b;
        double_stage_cpx_t error_a;
        double_stage_cpx_t error_b;

        fixed_a.re = fixed_stage_q19_14_to_real(fixed_output.a.re);
        fixed_a.im = fixed_stage_q19_14_to_real(fixed_output.a.im);
        fixed_b.re = fixed_stage_q19_14_to_real(fixed_output.b.re);
        fixed_b.im = fixed_stage_q19_14_to_real(fixed_output.b.im);

        // SQNR reference is the ideal double model, noise is the fixed-point error.
        error_a.re = reference_output.a.re - fixed_a.re;
        error_a.im = reference_output.a.im - fixed_a.im;
        error_b.re = reference_output.b.re - fixed_b.re;
        error_b.im = reference_output.b.im - fixed_b.im;

        reference_power += compare_cpx_power(reference_output.a);
        reference_power += compare_cpx_power(reference_output.b);

        error_power += compare_cpx_power(error_a);
        error_power += compare_cpx_power(error_b);

        printf("call=%2d last_i=%d\n", pair_index, last_i);
        compare_print_complex("fixed_a_o", fixed_a);
        compare_print_complex("ref_a_o", reference_output.a);
        compare_print_complex("err_a_o", error_a);
        compare_print_complex("fixed_b_o", fixed_b);
        compare_print_complex("ref_b_o", reference_output.b);
        compare_print_complex("err_b_o", error_b);
    }

    printf("\nReference power = %.12f\n", reference_power);
    printf("Error power     = %.12f\n", error_power);

    if (error_power == 0.0) {
        printf("SQNR = inf dB\n");
    } else {
        printf("SQNR = %.12f dB\n", compare_sqnr_db(reference_power, error_power));
    }
}

int main(void) {
    compare_run();
    return 0;
}
