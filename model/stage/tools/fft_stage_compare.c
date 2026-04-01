#ifndef FFT_N
#define FFT_N 64
#endif

#ifndef WHITE_NOISE_BACKOFF_DB
#define WHITE_NOISE_BACKOFF_DB 10.0
#endif

#include "../fixed/fft_stage_model_fixed.h"
#include "../reference/fft_stage_model_double.h"

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define COMPARE_PAIR_COUNT (FFT_N / 2)

/* ===== Comparison math ===== */

static double compare_white_noise_backoff_linear(void) {
    return pow(10.0, WHITE_NOISE_BACKOFF_DB / 20.0);
}

static int16_t compare_quantize_normalized_to_q16_0(
    double normalized_noise,
    double backoff_linear
) {
    double backed_off_noise = normalized_noise / backoff_linear;
    long quantized = lround(backed_off_noise * (double)INT16_MAX);

    if (quantized > INT16_MAX) {
        quantized = INT16_MAX;
    }

    if (quantized < -INT16_MAX) {
        quantized = -INT16_MAX;
    }

    return (int16_t)quantized;
}

static double_stage_cpx_t compare_q16_input_to_double(fixed_stage_cpx_q16_0_t value) {
    double_stage_cpx_t result;

    result.re = (double)value.re;
    result.im = (double)value.im;

    return result;
}

static double_stage_cpx_t compare_fixed_output_to_double(fixed_stage_cpx_q16_0_t value) {
    double_stage_cpx_t result;

    result.re = (double)value.re;
    result.im = (double)value.im;

    return result;
}

static double compare_cpx_power(double_stage_cpx_t value) {
    return (value.re * value.re) + (value.im * value.im);
}

// SQNR = 10 * log10(sum(|signal|^2) / sum(|error|^2)).
static double compare_sqnr_db(double signal_power, double noise_power) {
    if (noise_power <= 0.0) {
        return INFINITY;
    }

    return 10.0 * log10(signal_power / noise_power);
}

/* ===== Stimulus and formatted output ===== */

static int16_t compare_white_noise_q16_0_sample(double backoff_linear) {
    double normalized_noise = -1.0 + (2.0 * (double)rand() / (double)RAND_MAX);

    return compare_quantize_normalized_to_q16_0(normalized_noise, backoff_linear);
}

static void compare_fill_white_noise_signal(
    fixed_stage_cpx_q16_0_t signal[FFT_N],
    double backoff_linear
) {
    for (int i = 0; i < FFT_N; ++i) {
        signal[i].re = compare_white_noise_q16_0_sample(backoff_linear);
        signal[i].im = compare_white_noise_q16_0_sample(backoff_linear);
    }
}

static void compare_print_complex(const char *name, double_stage_cpx_t value) {
    printf("  %s: re=% .12f, im=% .12f\n", name, value.re, value.im);
}

/* ===== Comparison runner ===== */

static void compare_run(void) {
    fixed_stage_model_t fixed_model = {0};
    double_stage_model_t double_model = {0};
    fixed_stage_cpx_q16_0_t signal[FFT_N];
    double backoff_linear = compare_white_noise_backoff_linear();
    double reference_power = 0.0;
    double error_power = 0.0;

    srand(1);
    compare_fill_white_noise_signal(signal, backoff_linear);

    printf(
        "Stage model comparison, FFT_N=%d, backoff=%.2f dB, scale=1/%.6f\n\n",
        FFT_N,
        WHITE_NOISE_BACKOFF_DB,
        backoff_linear
    );

    for (int pair_index = 0; pair_index < COMPARE_PAIR_COUNT; ++pair_index) {
        int last_i = (pair_index == (COMPARE_PAIR_COUNT - 1));
        fixed_stage_cpx_q16_0_t a_fixed = signal[2 * pair_index];
        fixed_stage_cpx_q16_0_t b_fixed = signal[(2 * pair_index) + 1];
        double_stage_cpx_t a_double = compare_q16_input_to_double(a_fixed);
        double_stage_cpx_t b_double = compare_q16_input_to_double(b_fixed);
        fixed_stage_output_t fixed_output = fixed_stage_step(&fixed_model, a_fixed, b_fixed, last_i);
        double_stage_output_t reference_output = double_stage_step(&double_model, a_double, b_double, last_i);
        double_stage_cpx_t fixed_a = compare_fixed_output_to_double(fixed_output.a);
        double_stage_cpx_t fixed_b = compare_fixed_output_to_double(fixed_output.b);
        double_stage_cpx_t error_a;
        double_stage_cpx_t error_b;

        // SQNR uses the ideal double-precision output as the signal and the
        // fixed-point deviation from that output as the noise.
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
