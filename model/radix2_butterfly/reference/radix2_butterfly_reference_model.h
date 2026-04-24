#ifndef RADIX2_BUTTERFLY_REFERENCE_MODEL_H
#define RADIX2_BUTTERFLY_REFERENCE_MODEL_H

#ifndef FFT_N
#define FFT_N 64
#endif

typedef struct {
    double re;
    double im;
} radix2_butterfly_reference_cpx_t;

typedef struct {
    int last;
    radix2_butterfly_reference_cpx_t a;
    radix2_butterfly_reference_cpx_t b;
} radix2_butterfly_reference_output_t;

typedef struct {
    int twiddle_index;
} radix2_butterfly_reference_model_t;

/*
 * Выполняет один шаг reference-модели radix2_butterfly.
 * Принимает два входных отсчёта `a_i` и `b_i`,
 * использует текущий twiddle из состояния `model`,
 * возвращает выходы stage в double и пробрасывает `last_i` в `last`.
 * Если `last_i != 0`, индекс twiddle сбрасывается для следующего вызова.
 */
radix2_butterfly_reference_output_t radix2_butterfly_reference_step(
    radix2_butterfly_reference_model_t *model,
    radix2_butterfly_reference_cpx_t a_i,
    radix2_butterfly_reference_cpx_t b_i,
    int last_i
);

#endif
