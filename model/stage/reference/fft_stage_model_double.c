#include "fft_stage_model_double.h"

#include <math.h>

#define PI 3.14159265358979323846

static double_stage_cpx_t double_stage_calc_twiddle(int twiddle_index) {
    double angle = 2.0 * PI * (double)twiddle_index / (double)FFT_N;

    return (double_stage_cpx_t){
        .re = cos(angle),
        .im = -sin(angle)
    };
}

static double_stage_cpx_t double_stage_complex_mul(double_stage_cpx_t x, double_stage_cpx_t y) {
    return (double_stage_cpx_t){
        .re = (x.re * y.re) - (x.im * y.im),
        .im = (x.re * y.im) + (x.im * y.re)
    };
}

double_stage_output_t double_stage_step(
    double_stage_model_t *model,
    double_stage_cpx_t a_i,
    double_stage_cpx_t b_i,
    int last_i
) {
    // Твидлы
    int current_twiddle_index = model->twiddle_index;
    double_stage_cpx_t twiddle = double_stage_calc_twiddle(current_twiddle_index);
    double inv_sqrt2 = 1.0 / sqrt(2.0);

    // Получение bW
    double_stage_cpx_t bw = double_stage_complex_mul(b_i, twiddle);

    // Бабочка
    double_stage_cpx_t sum = {
        .re = a_i.re + bw.re,
        .im = a_i.im + bw.im
    };
    double_stage_cpx_t diff = {
        .re = a_i.re - bw.re,
        .im = a_i.im - bw.im
    };

    // Масштабирование на 1 / sqrt(2)
    double_stage_output_t output = {
        .last = last_i,
        .a.re = sum.re * inv_sqrt2,
        .a.im = sum.im * inv_sqrt2,
        .b.re = diff.re * inv_sqrt2,
        .b.im = diff.im * inv_sqrt2
    };

    if (last_i || (current_twiddle_index == ((FFT_N / 2) - 1))) {
        model->twiddle_index = 0;
    } else {
        model->twiddle_index = current_twiddle_index + 1;
    }

    return output;
}
