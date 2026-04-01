#include <stdint.h>
#include <stdio.h>

typedef struct {
    int16_t re;
    int16_t im;
} cpx_q16_0_t;

typedef struct {
    int16_t re;
    int16_t im;
} cpx_q2_14_t;

typedef struct {
    int32_t re;
    int32_t im;
} cpx_q18_14_t;

static cpx_q18_14_t cpx_mul_q16_0_q2_14(cpx_q16_0_t a, cpx_q2_14_t b) {
    cpx_q18_14_t y;

    int32_t ar_br = (int32_t)a.re * (int32_t)b.re;
    int32_t ai_bi = (int32_t)a.im * (int32_t)b.im;
    int32_t ar_bi = (int32_t)a.re * (int32_t)b.im;
    int32_t ai_br = (int32_t)a.im * (int32_t)b.re;

    // Q16.0 * Q2.14 -> Q18.14
    y.re = ar_br - ai_bi;
    y.im = ar_bi + ai_br;

    return y;
}

void cpx_mul_q16_0_q2_14_dpi(
    int16_t a_re,
    int16_t a_im,
    int16_t b_re,
    int16_t b_im,
    int32_t *y_re,
    int32_t *y_im
) {
    cpx_q16_0_t a = {a_re, a_im};
    cpx_q2_14_t b = {b_re, b_im};
    cpx_q18_14_t y = cpx_mul_q16_0_q2_14(a, b);

    *y_re = y.re;
    *y_im = y.im;
}

typedef struct {
    const char *name;
    cpx_q16_0_t a;
    cpx_q2_14_t b;
    cpx_q18_14_t expected;
} test_vec_t;

int main(void) {
    const test_vec_t tests[] = {
        {
            "t1",
            {3, 2},            // (3, 2) in Q16.0
            {24576, -4096},    // (1.5, -0.25) in Q2.14
            {81920, 36864}     // (5, 2.25) in Q18.14
        },
        {
            "t2",
            {-7, 4},           // (-7, 4) in Q16.0
            {-16384, 8192},    // (-1, 0.5) in Q2.14
            {81920, -122880}   // (5, -7.5) in Q18.14
        },
        {
            "t3",
            {32767, -32768},   // (32767, -32768) in Q16.0
            {8192, 8192},      // (0.5, 0.5) in Q2.14
            {536862720, -8192} // (32767.5, -0.5) in Q18.14
        },
    };

    int fails = 0;
    const int count = (int)(sizeof(tests) / sizeof(tests[0]));

    for (int i = 0; i < count; ++i) {
        int32_t y_re = 0;
        int32_t y_im = 0;

        cpx_mul_q16_0_q2_14_dpi(
            tests[i].a.re,
            tests[i].a.im,
            tests[i].b.re,
            tests[i].b.im,
            &y_re,
            &y_im
        );

        if (y_re != tests[i].expected.re || y_im != tests[i].expected.im) {
            ++fails;
            printf("FAIL %s: got (%d, %d), expected (%d, %d)\n",
                   tests[i].name,
                   y_re,
                   y_im,
                   tests[i].expected.re,
                   tests[i].expected.im);
        } else {
            printf("PASS %s\n", tests[i].name);
        }
    }

    printf("Summary: %d/%d passed\n", count - fails, count);
    return (fails == 0) ? 0 : 1;
}
