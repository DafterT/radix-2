#ifndef RADIX2_FFT_STAGE_MODEL_H
#define RADIX2_FFT_STAGE_MODEL_H

#include <stdint.h>

#ifndef FFT_N
#define FFT_N 64
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
    int last;
    fixed_stage_cpx_q16_0_t a;
    fixed_stage_cpx_q16_0_t b;
} fixed_stage_output_t;

typedef struct {
    int twiddle_index;
} fixed_stage_model_t;

/*
 * Выполняет один шаг модели FFT stage.
 * Принимает два входных отсчёта `a_i` и `b_i` в формате Q16.0,
 * использует текущий twiddle из состояния `model`,
 * возвращает выходы stage в формате Q16.0 и пробрасывает `last_i` в `last`.
 * Если `last_i != 0`, индекс twiddle сбрасывается для следующего вызова.
 */
fixed_stage_output_t fixed_stage_step(
    fixed_stage_model_t *model,
    fixed_stage_cpx_q16_0_t a_i,
    fixed_stage_cpx_q16_0_t b_i,
    int last_i
);

#endif
