#ifndef RADIX2_BUTTERFLY_FIXED_MODEL_H
#define RADIX2_BUTTERFLY_FIXED_MODEL_H

#include <stdint.h>

#ifndef FFT_N
#define FFT_N 64
#endif

typedef struct {
    int16_t re;
    int16_t im;
} radix2_butterfly_fixed_cpx_q16_0_t;

typedef struct {
    int16_t re;
    int16_t im;
} radix2_butterfly_fixed_cpx_q2_14_t;

typedef struct {
    int last;
    radix2_butterfly_fixed_cpx_q16_0_t a;
    radix2_butterfly_fixed_cpx_q16_0_t b;
} radix2_butterfly_fixed_output_t;

typedef struct {
    int twiddle_index;
} radix2_butterfly_fixed_model_t;

/*
 * Выполняет один шаг fixed-модели radix2_butterfly.
 * Принимает два входных отсчёта `a_i` и `b_i` в формате Q16.0,
 * использует текущий twiddle из состояния `model`,
 * возвращает выходы stage в формате Q16.0 и пробрасывает `last_i` в `last`.
 * Если `last_i != 0`, индекс twiddle сбрасывается для следующего вызова.
 */
radix2_butterfly_fixed_output_t radix2_butterfly_fixed_step(
    radix2_butterfly_fixed_model_t *model,
    radix2_butterfly_fixed_cpx_q16_0_t a_i,
    radix2_butterfly_fixed_cpx_q16_0_t b_i,
    int last_i
);

#endif
