#ifndef RADIX2_FFT_STAGE_MODEL_H
#define RADIX2_FFT_STAGE_MODEL_H

#include <stdint.h>

#ifndef FFT_N
#define FFT_N 64
#endif

#ifndef FIXED_STAGE_FRAC_BITS
#define FIXED_STAGE_FRAC_BITS 14
#endif

#ifndef WHITE_NOISE_BACKOFF_DB
#define WHITE_NOISE_BACKOFF_DB 6.0
#endif

#define FIXED_STAGE_TWIDDLE_COUNT (FFT_N / 2)

typedef struct {
    int16_t re;
    int16_t im;
} fixed_stage_cpx_q16_0_t;

typedef struct {
    int16_t re;
    int16_t im;
} fixed_stage_cpx_q2_14_t;

typedef struct {
    int32_t re;
    int32_t im;
} fixed_stage_cpx_q19_14_t;

typedef struct {
    int last;
    fixed_stage_cpx_q19_14_t a;
    fixed_stage_cpx_q19_14_t b;
} fixed_stage_output_t;

typedef struct {
    int initialized;
    int twiddle_index;
    fixed_stage_cpx_q2_14_t twiddles[FIXED_STAGE_TWIDDLE_COUNT];
} fixed_stage_model_t;

/* ===== Core model API ===== */

double fixed_stage_q19_14_to_real(int32_t value);
void fixed_stage_init(fixed_stage_model_t *model);
fixed_stage_output_t fixed_stage_step(
    fixed_stage_model_t *model,
    int last_i,
    fixed_stage_cpx_q16_0_t a_i,
    fixed_stage_cpx_q16_0_t b_i
);

/* ===== Demo / test helpers ===== */

void fixed_stage_run_demo(void);

#endif
