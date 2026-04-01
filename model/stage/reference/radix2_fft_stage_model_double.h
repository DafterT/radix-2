#ifndef RADIX2_FFT_STAGE_MODEL_DOUBLE_H
#define RADIX2_FFT_STAGE_MODEL_DOUBLE_H

#include <stdint.h>

#ifndef FFT_N
#define FFT_N 64
#endif

#ifndef WHITE_NOISE_BACKOFF_DB
#define WHITE_NOISE_BACKOFF_DB 6.0
#endif

#define DOUBLE_STAGE_TWIDDLE_COUNT (FFT_N / 2)

typedef struct {
    double re;
    double im;
} double_stage_cpx_t;

typedef struct {
    int last;
    double_stage_cpx_t a;
    double_stage_cpx_t b;
} double_stage_output_t;

typedef struct {
    int initialized;
    int twiddle_index;
    double_stage_cpx_t twiddles[DOUBLE_STAGE_TWIDDLE_COUNT];
} double_stage_model_t;

/* ===== Core model API ===== */

void double_stage_init(double_stage_model_t *model);
double_stage_output_t double_stage_step(
    double_stage_model_t *model,
    int last_i,
    double_stage_cpx_t a_i,
    double_stage_cpx_t b_i
);

/* ===== Demo / test helpers ===== */

void double_stage_run_demo(void);

#endif
