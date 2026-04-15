#ifndef WHITE_NOISE_BACKOFF_DB
#define WHITE_NOISE_BACKOFF_DB 20.0
#endif

#ifndef FFT64_COMPARE_RUNS
#define FFT64_COMPARE_RUNS 1000
#endif

#ifndef FFT64_COMPARE_PRINT_RUNS
#define FFT64_COMPARE_PRINT_RUNS 0
#endif

#include "../fixed_sqrt2/model_fixed.h"
#include "../reference/model_double.h"

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define INPUT_WIDTH 16

fft64_fixed_result_t fft64_radix2_fixed_div2(
    const fft64_fixed_cpx_q16_0_t input[FFT64_FIXED_SIZE]
);

fft64_fixed_result_t fft64_radix2_fixed_collect(
    const fft64_fixed_cpx_q16_0_t input[FFT64_FIXED_SIZE]
);

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

static double compare_reference_output_scale_div2(void) {
    double scale = 1.0;
    int stage_index = 0;

    for (int stage_size = 2; stage_size <= FFT64_SIZE; stage_size *= 2) {
        if ((stage_index & 1) != 0) {
            scale *= 0.5;
        }

        stage_index += 1;
    }

    return scale;
}

static double compare_reference_output_scale_collect(void) {
    return 1.0 / 8.0;
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
    const double reference_output_scale_sqrt2 = compare_reference_output_scale();
    const double reference_output_scale_div2 = compare_reference_output_scale_div2();
    const double reference_output_scale_collect = compare_reference_output_scale_collect();
    double sqrt2_sqnr_sum_db = 0.0;
    double sqrt2_total_error_mag = 0.0;
    double sqrt2_max_error_mag = 0.0;
    double div2_sqnr_sum_db = 0.0;
    double div2_total_error_mag = 0.0;
    double div2_max_error_mag = 0.0;
    double collect_sqnr_sum_db = 0.0;
    double collect_total_error_mag = 0.0;
    double collect_max_error_mag = 0.0;

    srand(1);

    printf("FFT64 size         = %d\n", FFT64_FIXED_SIZE);
    printf("Runs               = %d\n", FFT64_COMPARE_RUNS);
    printf("Bins per run       = %d\n", FFT64_FIXED_SIZE);
    printf("Total bins         = %d\n", FFT64_COMPARE_RUNS * FFT64_FIXED_SIZE);
    printf("Backoff            = %.3f dB\n", WHITE_NOISE_BACKOFF_DB);
    printf("Input scale        = %.3f\n", input_scale);
    printf("Reference scale sqrt2 = %.9f\n", reference_output_scale_sqrt2);
    printf("Reference scale div2  = %.9f\n", reference_output_scale_div2);
    printf("Reference scale collect = %.9f\n\n", reference_output_scale_collect);

    for (int run = 0; run < FFT64_COMPARE_RUNS; ++run) {
        fft64_fixed_cpx_q16_0_t fixed_input[FFT64_FIXED_SIZE];
        fft64_complex_t reference_input[FFT64_SIZE];
        fft64_fixed_result_t fixed_sqrt2_output;
        fft64_fixed_result_t fixed_div2_output;
        fft64_fixed_result_t fixed_collect_output;
        fft64_result_t reference_output;
        double sqrt2_run_error_mag = 0.0;
        double sqrt2_run_max_error_mag = 0.0;
        double sqrt2_signal_power = 0.0;
        double sqrt2_noise_power = 0.0;
        double div2_run_error_mag = 0.0;
        double div2_run_max_error_mag = 0.0;
        double div2_signal_power = 0.0;
        double div2_noise_power = 0.0;
        double collect_run_error_mag = 0.0;
        double collect_run_max_error_mag = 0.0;
        double collect_signal_power = 0.0;
        double collect_noise_power = 0.0;

        for (int i = 0; i < FFT64_FIXED_SIZE; ++i) {
            fixed_input[i] = compare_make_fixed_input(input_scale);
            reference_input[i] = compare_fixed_to_double(fixed_input[i]);
        }

        fixed_sqrt2_output = fft64_radix2_fixed(fixed_input);
        fixed_div2_output = fft64_radix2_fixed_div2(fixed_input);
        fixed_collect_output = fft64_radix2_fixed_collect(fixed_input);
        reference_output = fft64_radix2(reference_input);

        for (int bin = 0; bin < FFT64_FIXED_SIZE; ++bin) {
            fft64_complex_t fixed_sqrt2_bin = compare_fixed_to_double(fixed_sqrt2_output.bins[bin]);
            fft64_complex_t fixed_div2_bin = compare_fixed_to_double(fixed_div2_output.bins[bin]);
            fft64_complex_t fixed_collect_bin = compare_fixed_to_double(fixed_collect_output.bins[bin]);
            fft64_complex_t reference_sqrt2_bin = {
                .re = reference_output.bins[bin].re * reference_output_scale_sqrt2,
                .im = reference_output.bins[bin].im * reference_output_scale_sqrt2
            };
            fft64_complex_t reference_div2_bin = {
                .re = reference_output.bins[bin].re * reference_output_scale_div2,
                .im = reference_output.bins[bin].im * reference_output_scale_div2
            };
            fft64_complex_t reference_collect_bin = {
                .re = reference_output.bins[bin].re * reference_output_scale_collect,
                .im = reference_output.bins[bin].im * reference_output_scale_collect
            };
            double sqrt2_error_mag = compare_cpx_error_mag(reference_sqrt2_bin, fixed_sqrt2_bin);
            double div2_error_mag = compare_cpx_error_mag(reference_div2_bin, fixed_div2_bin);
            double collect_error_mag = compare_cpx_error_mag(reference_collect_bin, fixed_collect_bin);
            fft64_complex_t sqrt2_error_bin = {
                .re = reference_sqrt2_bin.re - fixed_sqrt2_bin.re,
                .im = reference_sqrt2_bin.im - fixed_sqrt2_bin.im
            };
            fft64_complex_t div2_error_bin = {
                .re = reference_div2_bin.re - fixed_div2_bin.re,
                .im = reference_div2_bin.im - fixed_div2_bin.im
            };
            fft64_complex_t collect_error_bin = {
                .re = reference_collect_bin.re - fixed_collect_bin.re,
                .im = reference_collect_bin.im - fixed_collect_bin.im
            };

            sqrt2_run_error_mag += sqrt2_error_mag;
            sqrt2_total_error_mag += sqrt2_error_mag;
            sqrt2_signal_power += compare_cpx_power(reference_sqrt2_bin);
            sqrt2_noise_power += compare_cpx_power(sqrt2_error_bin);

            if (sqrt2_error_mag > sqrt2_run_max_error_mag) {
                sqrt2_run_max_error_mag = sqrt2_error_mag;
            }

            if (sqrt2_error_mag > sqrt2_max_error_mag) {
                sqrt2_max_error_mag = sqrt2_error_mag;
            }

            div2_run_error_mag += div2_error_mag;
            div2_total_error_mag += div2_error_mag;
            div2_signal_power += compare_cpx_power(reference_div2_bin);
            div2_noise_power += compare_cpx_power(div2_error_bin);

            if (div2_error_mag > div2_run_max_error_mag) {
                div2_run_max_error_mag = div2_error_mag;
            }

            if (div2_error_mag > div2_max_error_mag) {
                div2_max_error_mag = div2_error_mag;
            }

            collect_run_error_mag += collect_error_mag;
            collect_total_error_mag += collect_error_mag;
            collect_signal_power += compare_cpx_power(reference_collect_bin);
            collect_noise_power += compare_cpx_power(collect_error_bin);

            if (collect_error_mag > collect_run_max_error_mag) {
                collect_run_max_error_mag = collect_error_mag;
            }

            if (collect_error_mag > collect_max_error_mag) {
                collect_max_error_mag = collect_error_mag;
            }
        }
        double sqrt2_run_sqnr_db = compare_sqnr_db(sqrt2_signal_power, sqrt2_noise_power);
        double div2_run_sqnr_db = compare_sqnr_db(div2_signal_power, div2_noise_power);
        double collect_run_sqnr_db = compare_sqnr_db(collect_signal_power, collect_noise_power);

        sqrt2_sqnr_sum_db += sqrt2_run_sqnr_db;
        div2_sqnr_sum_db += div2_run_sqnr_db;
        collect_sqnr_sum_db += collect_run_sqnr_db;

        if (FFT64_COMPARE_PRINT_RUNS != 0) {
            printf(
                "run=%d sqrt2: avg_error=%.6f max_error=%.6f signal_power=%.3f noise_power=%.3f sqnr=%.3f dB | div2: avg_error=%.6f max_error=%.6f signal_power=%.3f noise_power=%.3f sqnr=%.3f dB | collect: avg_error=%.6f max_error=%.6f signal_power=%.3f noise_power=%.3f sqnr=%.3f dB\n",
                run,
                sqrt2_run_error_mag / (double)FFT64_FIXED_SIZE,
                sqrt2_run_max_error_mag,
                sqrt2_signal_power,
                sqrt2_noise_power,
                sqrt2_run_sqnr_db,
                div2_run_error_mag / (double)FFT64_FIXED_SIZE,
                div2_run_max_error_mag,
                div2_signal_power,
                div2_noise_power,
                div2_run_sqnr_db,
                collect_run_error_mag / (double)FFT64_FIXED_SIZE,
                collect_run_max_error_mag,
                collect_signal_power,
                collect_noise_power,
                collect_run_sqnr_db
            );
        }
    }

    printf(
        "\n[sqrt2] Average error = %.6f\n[sqrt2] Maximum error = %.6f\n[sqrt2] Average SQNR  = %.3f dB\n",
        sqrt2_total_error_mag / (double)(FFT64_COMPARE_RUNS * FFT64_FIXED_SIZE),
        sqrt2_max_error_mag,
        sqrt2_sqnr_sum_db / (double)FFT64_COMPARE_RUNS
    );
    printf(
        "\n[div2]  Average error = %.6f\n[div2]  Maximum error = %.6f\n[div2]  Average SQNR  = %.3f dB\n",
        div2_total_error_mag / (double)(FFT64_COMPARE_RUNS * FFT64_FIXED_SIZE),
        div2_max_error_mag,
        div2_sqnr_sum_db / (double)FFT64_COMPARE_RUNS
    );
    printf(
        "\n[collect] Average error = %.6f\n[collect] Maximum error = %.6f\n[collect] Average SQNR  = %.3f dB\n",
        collect_total_error_mag / (double)(FFT64_COMPARE_RUNS * FFT64_FIXED_SIZE),
        collect_max_error_mag,
        collect_sqnr_sum_db / (double)FFT64_COMPARE_RUNS
    );

    return 0;
}
