#include "fft_stage_model_fixed.h"

#include <math.h>
#include <stdint.h>

#define PI 3.14159265358979323846

// INV_SQRT2_Q1_17 = $rtoi((1 / sqrt(2)) * 2^17)
#define INV_SQRT2_Q1_17 ((int64_t)92681)

typedef struct {
    int64_t re;
    int64_t im;
} fixed_stage_cpx_i64_t;

enum {
    FIXED_STAGE_FRAC_BITS = 14
};

/*
 * Обрезает `value` до ровно `width` бит и затем интерпретирует результат как
 * знаковое число в дополнительном коде той же ширины.
 */
static int64_t fixed_stage_wrap_signed(int64_t value, int width) {
    // Маска по ширине бит числа
    uint64_t mask = (UINT64_C(1) << width) - 1U;
    // Обрезаем значение по маске
    uint64_t wrapped = (uint64_t)value & mask;
    // Вычисляем знак
    uint64_t sign_bit = UINT64_C(1) << (width - 1);
    // Если число отрицательно расширяем знак
    if ((wrapped & sign_bit) != 0U) {
        wrapped |= ~mask;
    }

    return (int64_t)wrapped;
}

static fixed_stage_cpx_q2_14_t fixed_stage_calc_twiddle(int twiddle_index) {
    fixed_stage_cpx_q2_14_t twiddle;
    double angle = 2.0 * PI * (double)twiddle_index / (double)FFT_N;

    twiddle.re = (int16_t)fixed_stage_wrap_signed(
        (int64_t)lround(cos(angle) * (double)(1 << FIXED_STAGE_FRAC_BITS)),
        16
    );
    twiddle.im = (int16_t)fixed_stage_wrap_signed(
        (int64_t)lround(-sin(angle) * (double)(1 << FIXED_STAGE_FRAC_BITS)),
        16
    );

    return twiddle;
}

static fixed_stage_cpx_i64_t fixed_stage_complex_mul_q16_0_q2_14(
    fixed_stage_cpx_q16_0_t x_q16_0,
    fixed_stage_cpx_q2_14_t y_q2_14
) {
    return (fixed_stage_cpx_i64_t){
        .re = fixed_stage_wrap_signed(
            ((int64_t)x_q16_0.re * (int64_t)y_q2_14.re) -
            ((int64_t)x_q16_0.im * (int64_t)y_q2_14.im),
            33
        ),
        .im = fixed_stage_wrap_signed(
            ((int64_t)x_q16_0.re * (int64_t)y_q2_14.im) +
            ((int64_t)x_q16_0.im * (int64_t)y_q2_14.re),
            33
        )
    };
}

static int16_t fixed_stage_round_clip_q22_23_to_q16_0(int64_t value_q22_23) {
    value_q22_23 = fixed_stage_wrap_signed(value_q22_23, 45);

    // Целая часть после отбрасывания 23 дробных бит.
    int64_t rounded_q22_0 = value_q22_23 >> 23;

    // Дробная часть хранится в младших 23 битах.
    int64_t frac_q22_23 = value_q22_23 & ((INT64_C(1) << 23) - 1);
    int round_up = 0;

    // Больше 0.5 => округляем вверх.
    if (frac_q22_23 > (INT64_C(1) << 22)) {
        round_up = 1;
    }

    // Ровно 0.5 => округляем к чётному.
    if ((frac_q22_23 == (INT64_C(1) << 22)) && ((rounded_q22_0 & 1) != 0)) {
        round_up = 1;
    }

    if (round_up) {
        rounded_q22_0 += 1;
    }

    // Клипинг
    const int64_t max_q16_0 = ((int64_t)1 << 15) - 1;
    const int64_t min_q16_0 = -max_q16_0;

    if (rounded_q22_0 > max_q16_0) {
        return (int16_t)max_q16_0;
    }

    if (rounded_q22_0 < min_q16_0) {
        return (int16_t)min_q16_0;
    }

    return (int16_t)rounded_q22_0;
}

fixed_stage_output_t fixed_stage_step(
    fixed_stage_model_t *model,
    fixed_stage_cpx_q16_0_t a_i,
    fixed_stage_cpx_q16_0_t b_i,
    int last_i
) {
    // Коэффициент твидлов
    int current_twiddle_index = model->twiddle_index;
    fixed_stage_cpx_q2_14_t twiddle_q2_14 = fixed_stage_calc_twiddle(current_twiddle_index);

    // Получение bW
    fixed_stage_cpx_i64_t bw_q19_14 = fixed_stage_complex_mul_q16_0_q2_14(b_i, twiddle_q2_14);

    // Подгонка a и bW к q20.14
    fixed_stage_cpx_i64_t a_q20_14 = {
        .re = (int64_t)a_i.re << 14,
        .im = (int64_t)a_i.im << 14
    };

    fixed_stage_cpx_i64_t bw_q20_14 = bw_q19_14;

    // Делаем a и bW q20.6
    fixed_stage_cpx_i64_t a_q20_6 = {
        .re = fixed_stage_wrap_signed(a_q20_14.re >> 8, 26),
        .im = fixed_stage_wrap_signed(a_q20_14.im >> 8, 26)
    };
    fixed_stage_cpx_i64_t bw_q20_6 = {
        .re = fixed_stage_wrap_signed(bw_q20_14.re >> 8, 26),
        .im = fixed_stage_wrap_signed(bw_q20_14.im >> 8, 26)
    };

    // Бабочка
    fixed_stage_cpx_i64_t sum_q21_6 = {
        .re = a_q20_6.re + bw_q20_6.re,
        .im = a_q20_6.im + bw_q20_6.im
    };
    fixed_stage_cpx_i64_t diff_q21_6 = {
        .re = a_q20_6.re - bw_q20_6.re,
        .im = a_q20_6.im - bw_q20_6.im
    };

    // Умножение на корень
    fixed_stage_cpx_i64_t a_out_q22_23 = {
        .re = sum_q21_6.re * INV_SQRT2_Q1_17,
        .im = sum_q21_6.im * INV_SQRT2_Q1_17
    };
    fixed_stage_cpx_i64_t b_out_q22_23 = {
        .re = diff_q21_6.re * INV_SQRT2_Q1_17,
        .im = diff_q21_6.im * INV_SQRT2_Q1_17
    };

    // Формирование выхода
    fixed_stage_output_t output = {
        .last = last_i,
        .a.re = fixed_stage_round_clip_q22_23_to_q16_0(a_out_q22_23.re),
        .a.im = fixed_stage_round_clip_q22_23_to_q16_0(a_out_q22_23.im),
        .b.re = fixed_stage_round_clip_q22_23_to_q16_0(b_out_q22_23.re),
        .b.im = fixed_stage_round_clip_q22_23_to_q16_0(b_out_q22_23.im)
    };

    if (last_i || (current_twiddle_index == (FIXED_STAGE_TWIDDLE_COUNT - 1))) {
        model->twiddle_index = 0;
    } else {
        model->twiddle_index = current_twiddle_index + 1;
    }

    return output;
}
