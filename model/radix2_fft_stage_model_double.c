#include "radix2_fft_stage_model_double.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define PI 3.14159265358979323846

// Validate double-precision stage model configuration.
static void double_stage_check_config(void) {
    if (FFT_N < 2) {
        fprintf(stderr, "radix2_fft_stage_model_double: FFT_N must be >= 2\n");
        exit(1);
    }

    if ((FFT_N & (FFT_N - 1)) != 0) {
        fprintf(stderr, "radix2_fft_stage_model_double: FFT_N must be power of two\n");
        exit(1);
    }

    if (WHITE_NOISE_BACKOFF_DB < 0.0) {
        fprintf(stderr, "radix2_fft_stage_model_double: WHITE_NOISE_BACKOFF_DB must be >= 0\n");
        exit(1);
    }
}

// Convert input backoff from dB to a linear amplitude scale.
static double double_stage_white_noise_backoff_linear(void) {
    return pow(10.0, WHITE_NOISE_BACKOFF_DB / 20.0);
}

static double_stage_cpx_t double_stage_cpx_mul(double_stage_cpx_t a, double_stage_cpx_t b) {
    double_stage_cpx_t result;

    result.re = (a.re * b.re) - (a.im * b.im);
    result.im = (a.re * b.im) + (a.im * b.re);

    return result;
}

// Precompute one FFT_N twiddle table in double format.
static void double_stage_compute_twiddles(double_stage_model_t *model) {
    for (int k = 0; k < DOUBLE_STAGE_TWIDDLE_COUNT; ++k) {
        double angle = 2.0 * PI * (double)k / (double)FFT_N;

        model->twiddles[k].re = cos(angle);
        model->twiddles[k].im = -sin(angle);
    }
}

// Initialize double stage state and reset the twiddle index.
void double_stage_init(double_stage_model_t *model) {
    double_stage_check_config();
    double_stage_compute_twiddles(model);
    model->twiddle_index = 0;
    model->initialized = 1;
}

// Execute one ideal stage butterfly with the current double twiddle.
double_stage_output_t double_stage_step(
    double_stage_model_t *model,
    int last_i,
    double_stage_cpx_t a_i,
    double_stage_cpx_t b_i
) {
    double_stage_output_t output;
    double_stage_cpx_t bw;
    double_stage_cpx_t twiddle;

    if (!model->initialized) {
        double_stage_init(model);
    }

    output.last = last_i;
    twiddle = model->twiddles[model->twiddle_index];
    bw = double_stage_cpx_mul(b_i, twiddle);

    output.a.re = a_i.re + bw.re;
    output.a.im = a_i.im + bw.im;
    output.b.re = a_i.re - bw.re;
    output.b.im = a_i.im - bw.im;

    if (last_i || (model->twiddle_index == (DOUBLE_STAGE_TWIDDLE_COUNT - 1))) {
        model->twiddle_index = 0;
    } else {
        model->twiddle_index += 1;
    }

    return output;
}

// Generate one local Q16.0-scaled double white-noise sample with dB backoff.
static double double_stage_white_noise_q16_0_scaled_sample(void) {
    double normalized_noise = -1.0 + (2.0 * (double)rand() / (double)RAND_MAX);
    double backed_off_noise = normalized_noise / double_stage_white_noise_backoff_linear();
    long quantized = lround(backed_off_noise * (double)INT16_MAX);

    if (quantized > INT16_MAX) {
        quantized = INT16_MAX;
    }

    if (quantized < -INT16_MAX) {
        quantized = -INT16_MAX;
    }

    return (double)quantized;
}

// Fill one local frame of Q16.0-scaled double white-noise samples.
static void double_stage_fill_white_noise_signal(double_stage_cpx_t signal[FFT_N]) {
    for (int i = 0; i < FFT_N; ++i) {
        signal[i].re = double_stage_white_noise_q16_0_scaled_sample();
        signal[i].im = double_stage_white_noise_q16_0_scaled_sample();
    }
}

// Print the double twiddle table once before running the model.
static void double_stage_print_twiddle_table(const double_stage_model_t *model) {
    printf(
        "Twiddle table, FFT_N=%d, count=%d, format=double:\n",
        FFT_N,
        DOUBLE_STAGE_TWIDDLE_COUNT
    );

    for (int i = 0; i < DOUBLE_STAGE_TWIDDLE_COUNT; ++i) {
        printf(
            "W[%2d]: re=% .12f, im=% .12f\n",
            i,
            model->twiddles[i].re,
            model->twiddles[i].im
        );
    }
}

static void double_stage_print_signal(const char *name, double_stage_cpx_t value) {
    printf(
        "  %s: re=% .12f, im=% .12f\n",
        name,
        value.re,
        value.im
    );
}

// Print one double-precision butterfly call in a human-readable format.
static void double_stage_print_step(
    int call_index,
    int twiddle_index,
    int last_i,
    double_stage_cpx_t a_i,
    double_stage_cpx_t b_i,
    double_stage_output_t output
) {
    printf(
        "call=%2d w_idx=%2d last_i=%d last_o=%d\n",
        call_index,
        twiddle_index,
        last_i,
        output.last
    );

    double_stage_print_signal("a_i", a_i);
    double_stage_print_signal("b_i", b_i);
    double_stage_print_signal("a_o", output.a);
    double_stage_print_signal("b_o", output.b);
}

// Run one double-precision frame of stage stimuli and print all butterflies.
void double_stage_run_demo(void) {
    double_stage_model_t model = {0};
    double_stage_cpx_t signal[FFT_N];

    srand(1);
    double_stage_fill_white_noise_signal(signal);
    double_stage_init(&model);

    printf(
        "Input stimulus: white noise in normalized range [-1, 1], backoff=%.2f dB, Q16.0-scaled double input, scale=1/%.6f\n\n",
        WHITE_NOISE_BACKOFF_DB,
        double_stage_white_noise_backoff_linear()
    );
    double_stage_print_twiddle_table(&model);
    printf("\nStage outputs for one 64-point frame:\n");

    for (int pair_index = 0; pair_index < DOUBLE_STAGE_TWIDDLE_COUNT; ++pair_index) {
        int last_i = (pair_index == (DOUBLE_STAGE_TWIDDLE_COUNT - 1));
        int twiddle_index = model.twiddle_index;
        double_stage_cpx_t a_i = signal[2 * pair_index];
        double_stage_cpx_t b_i = signal[(2 * pair_index) + 1];
        double_stage_output_t output = double_stage_step(&model, last_i, a_i, b_i);

        double_stage_print_step(pair_index, twiddle_index, last_i, a_i, b_i, output);
    }
}

#ifndef DOUBLE_STAGE_MODEL_NO_MAIN
int main(void) {
    double_stage_run_demo();
    return 0;
}
#endif
