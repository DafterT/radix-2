#ifndef FFT_STAGE_MODEL_DOUBLE_H
#define FFT_STAGE_MODEL_DOUBLE_H

#ifndef FFT_N
#define FFT_N 64
#endif

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
    int twiddle_index;
} double_stage_model_t;

/*
 * Выполняет один шаг double-модели FFT stage.
 * Принимает два входных отсчёта `a_i` и `b_i`,
 * использует текущий twiddle из состояния `model`,
 * возвращает выходы stage в double и пробрасывает `last_i` в `last`.
 * Если `last_i != 0`, индекс twiddle сбрасывается для следующего вызова.
 */
double_stage_output_t double_stage_step(
    double_stage_model_t *model,
    double_stage_cpx_t a_i,
    double_stage_cpx_t b_i,
    int last_i
);

#endif
