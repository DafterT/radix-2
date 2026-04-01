#include "radix2_fft_stage_model.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define PI 3.14159265358979323846

/* ===== Internal types ===== */

typedef struct {
    int32_t re;
    int32_t im;
} fixed_stage_cpx_q18_14_t;

/* ===== Core model helpers ===== */

static void fixed_stage_check_config(void) {
    if (FFT_N < 2) {
        fprintf(stderr, "radix2_fft_stage_model: FFT_N must be >= 2\n");
        exit(1);
    }

    if ((FFT_N & (FFT_N - 1)) != 0) {
        fprintf(stderr, "radix2_fft_stage_model: FFT_N must be power of two\n");
        exit(1);
    }

    if (WHITE_NOISE_BACKOFF_DB < 0.0) {
        fprintf(stderr, "radix2_fft_stage_model: WHITE_NOISE_BACKOFF_DB must be >= 0\n");
        exit(1);
    }
}

// Convert floating twiddle value to Q2.14.
static int16_t fixed_stage_real_to_q2_14(double value) {
    long scaled = lround(value * (double)(1 << FIXED_STAGE_FRAC_BITS));

    if (scaled > INT16_MAX) {
        scaled = INT16_MAX;
    }

    if (scaled < INT16_MIN) {
        scaled = INT16_MIN;
    }

    return (int16_t)scaled;
}

double fixed_stage_q19_14_to_real(int32_t value) {
    return (double)value / (double)(1 << FIXED_STAGE_FRAC_BITS);
}

static fixed_stage_cpx_q19_14_t fixed_stage_q16_0_to_q19_14(fixed_stage_cpx_q16_0_t value) {
    fixed_stage_cpx_q19_14_t result;

    result.re = (int32_t)value.re << FIXED_STAGE_FRAC_BITS;
    result.im = (int32_t)value.im << FIXED_STAGE_FRAC_BITS;

    return result;
}

static fixed_stage_cpx_q18_14_t fixed_stage_cpx_mul_q16_0_q2_14(
    fixed_stage_cpx_q16_0_t a,
    fixed_stage_cpx_q2_14_t b
) {
    fixed_stage_cpx_q18_14_t result;

    int32_t ar_br = (int32_t)a.re * (int32_t)b.re;
    int32_t ai_bi = (int32_t)a.im * (int32_t)b.im;
    int32_t ar_bi = (int32_t)a.re * (int32_t)b.im;
    int32_t ai_br = (int32_t)a.im * (int32_t)b.re;

    // Q16.0 * Q2.14 -> Q18.14
    result.re = ar_br - ai_bi;
    result.im = ar_bi + ai_br;

    return result;
}

static void fixed_stage_compute_twiddles(fixed_stage_model_t *model) {
    for (int k = 0; k < FIXED_STAGE_TWIDDLE_COUNT; ++k) {
        double angle = 2.0 * PI * (double)k / (double)FFT_N;

        model->twiddles[k].re = fixed_stage_real_to_q2_14(cos(angle));
        model->twiddles[k].im = fixed_stage_real_to_q2_14(-sin(angle));
    }
}

static void fixed_stage_advance_twiddle_index(fixed_stage_model_t *model, int last_i) {
    if (last_i || (model->twiddle_index == (FIXED_STAGE_TWIDDLE_COUNT - 1))) {
        model->twiddle_index = 0;
    } else {
        model->twiddle_index += 1;
    }
}

/* ===== Core model API ===== */

void fixed_stage_init(fixed_stage_model_t *model) {
    fixed_stage_check_config();
    fixed_stage_compute_twiddles(model);
    model->twiddle_index = 0;
    model->initialized = 1;
}

fixed_stage_output_t fixed_stage_step(
    fixed_stage_model_t *model,
    int last_i,
    fixed_stage_cpx_q16_0_t a_i,
    fixed_stage_cpx_q16_0_t b_i
) {
    fixed_stage_output_t output;
    fixed_stage_cpx_q19_14_t a_q19_14;
    fixed_stage_cpx_q18_14_t bw_q18_14;
    fixed_stage_cpx_q2_14_t twiddle;

    if (!model->initialized) {
        fixed_stage_init(model);
    }

    output.last = last_i;
    twiddle = model->twiddles[model->twiddle_index];

    a_q19_14 = fixed_stage_q16_0_to_q19_14(a_i);
    bw_q18_14 = fixed_stage_cpx_mul_q16_0_q2_14(b_i, twiddle);

    output.a.re = a_q19_14.re + bw_q18_14.re;
    output.a.im = a_q19_14.im + bw_q18_14.im;
    output.b.re = a_q19_14.re - bw_q18_14.re;
    output.b.im = a_q19_14.im - bw_q18_14.im;

    fixed_stage_advance_twiddle_index(model, last_i);

    return output;
}

/* ===== Demo / test helpers ===== */

static double fixed_stage_q2_14_to_real(int16_t value) {
    return (double)value / (double)(1 << FIXED_STAGE_FRAC_BITS);
}

static double fixed_stage_q16_0_to_real(int16_t value) {
    return (double)value;
}

static double fixed_stage_white_noise_backoff_linear(void) {
    return pow(10.0, WHITE_NOISE_BACKOFF_DB / 20.0);
}

static int16_t fixed_stage_quantize_normalized_to_q16_0(
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

static int16_t fixed_stage_white_noise_q16_0_sample(double backoff_linear) {
    double normalized_noise = -1.0 + (2.0 * (double)rand() / (double)RAND_MAX);

    return fixed_stage_quantize_normalized_to_q16_0(normalized_noise, backoff_linear);
}

static void fixed_stage_fill_white_noise_signal(
    fixed_stage_cpx_q16_0_t signal[FFT_N],
    double backoff_linear
) {
    for (int i = 0; i < FFT_N; ++i) {
        signal[i].re = fixed_stage_white_noise_q16_0_sample(backoff_linear);
        signal[i].im = fixed_stage_white_noise_q16_0_sample(backoff_linear);
    }
}

static uint32_t fixed_stage_pack_q2_14(fixed_stage_cpx_q2_14_t value) {
    return ((uint32_t)(uint16_t)value.im << 16) | (uint32_t)(uint16_t)value.re;
}

static uint64_t fixed_stage_pack_signed_33(int32_t value) {
    uint64_t packed = (uint64_t)(uint32_t)value;

    if (value < 0) {
        packed |= (1ULL << 32);
    }

    return packed;
}

static void fixed_stage_print_twiddle_table(const fixed_stage_model_t *model) {
    printf(
        "Twiddle table, FFT_N=%d, count=%d, format=Q2.14:\n",
        FFT_N,
        FIXED_STAGE_TWIDDLE_COUNT
    );

    for (int i = 0; i < FIXED_STAGE_TWIDDLE_COUNT; ++i) {
        printf(
            "W[%2d] = 0x%08X // re=%7d im=%7d // % .6f %+.6fj\n",
            i,
            fixed_stage_pack_q2_14(model->twiddles[i]),
            model->twiddles[i].re,
            model->twiddles[i].im,
            fixed_stage_q2_14_to_real(model->twiddles[i].re),
            fixed_stage_q2_14_to_real(model->twiddles[i].im)
        );
    }
}

static void fixed_stage_print_q16_0_signal(const char *name, fixed_stage_cpx_q16_0_t value) {
    printf(
        "  %s: re_bits=0x%04X re=% .6f, im_bits=0x%04X im=% .6f\n",
        name,
        (uint16_t)value.re,
        fixed_stage_q16_0_to_real(value.re),
        (uint16_t)value.im,
        fixed_stage_q16_0_to_real(value.im)
    );
}

static void fixed_stage_print_q19_14_signal(const char *name, fixed_stage_cpx_q19_14_t value) {
    printf(
        "  %s: re_bits=0x%09llX re=% .6f, im_bits=0x%09llX im=% .6f\n",
        name,
        (unsigned long long)fixed_stage_pack_signed_33(value.re),
        fixed_stage_q19_14_to_real(value.re),
        (unsigned long long)fixed_stage_pack_signed_33(value.im),
        fixed_stage_q19_14_to_real(value.im)
    );
}

static void fixed_stage_print_step(
    int call_index,
    int twiddle_index,
    int last_i,
    fixed_stage_cpx_q16_0_t a_i,
    fixed_stage_cpx_q16_0_t b_i,
    fixed_stage_output_t output
) {
    printf(
        "call=%2d w_idx=%2d last_i=%d last_o=%d\n",
        call_index,
        twiddle_index,
        last_i,
        output.last
    );

    fixed_stage_print_q16_0_signal("a_i", a_i);
    fixed_stage_print_q16_0_signal("b_i", b_i);
    fixed_stage_print_q19_14_signal("a_o", output.a);
    fixed_stage_print_q19_14_signal("b_o", output.b);
}

void fixed_stage_run_demo(void) {
    fixed_stage_model_t model = {0};
    fixed_stage_cpx_q16_0_t signal[FFT_N];
    double backoff_linear = fixed_stage_white_noise_backoff_linear();

    srand(1);
    fixed_stage_fill_white_noise_signal(signal, backoff_linear);
    fixed_stage_init(&model);

    printf(
        "Input stimulus: white noise in normalized range [-1, 1], backoff=%.2f dB, scale=1/%.6f\n\n",
        WHITE_NOISE_BACKOFF_DB,
        backoff_linear
    );
    fixed_stage_print_twiddle_table(&model);
    printf("\nStage outputs for one %d-point frame:\n", FFT_N);

    for (int pair_index = 0; pair_index < FIXED_STAGE_TWIDDLE_COUNT; ++pair_index) {
        int last_i = (pair_index == (FIXED_STAGE_TWIDDLE_COUNT - 1));
        int twiddle_index = model.twiddle_index;
        fixed_stage_cpx_q16_0_t a_i = signal[2 * pair_index];
        fixed_stage_cpx_q16_0_t b_i = signal[(2 * pair_index) + 1];
        fixed_stage_output_t output = fixed_stage_step(&model, last_i, a_i, b_i);

        fixed_stage_print_step(pair_index, twiddle_index, last_i, a_i, b_i, output);
    }
}

#ifndef FIXED_STAGE_MODEL_NO_MAIN
int main(void) {
    fixed_stage_run_demo();
    return 0;
}
#endif
