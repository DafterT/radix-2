#ifndef FFT_N
#define FFT_N 64
#endif

#ifndef WHITE_NOISE_BACKOFF_DB
#define WHITE_NOISE_BACKOFF_DB 0.0
#endif

#ifndef STAGE_COMPARE_RUNS
#define STAGE_COMPARE_RUNS 100
#endif

#include "../fixed/fft_stage_model_fixed.h"
#include "../reference/fft_stage_model_double.h"

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define STAGE_CALLS_PER_RUN (FFT_N / 2)
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

static fixed_stage_cpx_q16_0_t compare_make_fixed_input(double input_scale) {
    fixed_stage_cpx_q16_0_t sample;

    sample.re = compare_round_clip_q16_0(compare_random_unit_sample() * input_scale);
    sample.im = compare_round_clip_q16_0(compare_random_unit_sample() * input_scale);

    return sample;
}

static double_stage_cpx_t compare_fixed_to_double(fixed_stage_cpx_q16_0_t value) {
    double_stage_cpx_t result;

    result.re = (double)value.re;
    result.im = (double)value.im;

    return result;
}

static double compare_cpx_power(double_stage_cpx_t value) {
    return (value.re * value.re) + (value.im * value.im);
}

static double compare_sqnr_db(double signal_power, double noise_power) {
    if (noise_power <= 0.0) {
        return INFINITY;
    }

    return 10.0 * log10(signal_power / noise_power);
}

static void compare_print_fixed_cpx(const char *name, fixed_stage_cpx_q16_0_t value) {
    printf("  %-9s re=%10d im=%10d\n", name, value.re, value.im);
}

static void compare_print_double_cpx(const char *name, double_stage_cpx_t value) {
    printf("  %-9s re=%10.3f im=%10.3f\n", name, value.re, value.im);
}

int main(void) {
    const double max_q16_0 = (double)((1L << (INPUT_WIDTH - 1)) - 1L);
    const double fullscale_power = 2.0 * max_q16_0 * max_q16_0;
    const double backoff_ratio = pow(10.0, WHITE_NOISE_BACKOFF_DB / 10.0);
    const double input_scale = sqrt(fullscale_power / backoff_ratio);
    double sqnr_sum_db = 0.0;

    srand(1);

    printf("FFT_N              = %d\n", FFT_N);
    printf("Runs               = %d\n", STAGE_COMPARE_RUNS);
    printf("Calls per run      = %d\n", STAGE_CALLS_PER_RUN);
    printf("Total calls        = %d\n", STAGE_CALLS_PER_RUN * STAGE_COMPARE_RUNS);
    printf("Backoff            = %.3f dB\n", WHITE_NOISE_BACKOFF_DB);
    printf("Input scale        = %.3f\n\n", input_scale);

    for (int run = 0; run < STAGE_COMPARE_RUNS; ++run) {
        fixed_stage_model_t fixed_model = {0};
        double_stage_model_t double_model = {0};
        double signal_power = 0.0;
        double noise_power = 0.0;

        printf("run=%d\n", run);

        for (int call = 0; call < STAGE_CALLS_PER_RUN; ++call) {
            int last_i = (call == (STAGE_CALLS_PER_RUN - 1));
            fixed_stage_cpx_q16_0_t a_fixed = compare_make_fixed_input(input_scale);
            fixed_stage_cpx_q16_0_t b_fixed = compare_make_fixed_input(input_scale);
            double_stage_cpx_t a_double = compare_fixed_to_double(a_fixed);
            double_stage_cpx_t b_double = compare_fixed_to_double(b_fixed);
            fixed_stage_output_t fixed_out = fixed_stage_step(&fixed_model, a_fixed, b_fixed, last_i);
            double_stage_output_t double_out = double_stage_step(&double_model, a_double, b_double, last_i);
            double_stage_cpx_t fixed_a = compare_fixed_to_double(fixed_out.a);
            double_stage_cpx_t fixed_b = compare_fixed_to_double(fixed_out.b);
            double_stage_cpx_t err_a;
            double_stage_cpx_t err_b;

            err_a.re = double_out.a.re - fixed_a.re;
            err_a.im = double_out.a.im - fixed_a.im;
            err_b.re = double_out.b.re - fixed_b.re;
            err_b.im = double_out.b.im - fixed_b.im;

            signal_power += compare_cpx_power(double_out.a);
            signal_power += compare_cpx_power(double_out.b);
            noise_power += compare_cpx_power(err_a);
            noise_power += compare_cpx_power(err_b);

            printf(" call=%d last=%d\n", call, last_i);
            compare_print_fixed_cpx("a_i", a_fixed);
            compare_print_fixed_cpx("b_i", b_fixed);
            compare_print_double_cpx("fixed_a_o", fixed_a);
            compare_print_double_cpx("ref_a_o", double_out.a);
            compare_print_double_cpx("err_a_o", err_a);
            compare_print_double_cpx("fixed_b_o", fixed_b);
            compare_print_double_cpx("ref_b_o", double_out.b);
            compare_print_double_cpx("err_b_o", err_b);
            printf("\n");
        }

        double run_sqnr_db = compare_sqnr_db(signal_power, noise_power);

        sqnr_sum_db += run_sqnr_db;

        printf(" run_signal_power = %.3f\n", signal_power);
        printf(" run_error_power  = %.3f\n", noise_power);
        printf(" run_sqnr         = %.3f dB\n\n", run_sqnr_db);
    }

    printf("Average SQNR       = %.3f dB\n", sqnr_sum_db / (double)STAGE_COMPARE_RUNS);

    return 0;
}
