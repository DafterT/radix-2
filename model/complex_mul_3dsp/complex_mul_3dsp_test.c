#include <stdint.h>
#include <stdio.h>

#include "complex_mul_3dsp_model.h"

typedef struct {
    int16_t re;
    int16_t im;
} cpx_q16_0_t;

typedef struct {
    int16_t re;
    int16_t im;
} cpx_q2_14_t;

typedef struct {
    int64_t re;
    int64_t im;
} cpx_q19_14_t;

typedef struct {
    const char *name;
    cpx_q16_0_t a;
    cpx_q2_14_t b;
    cpx_q19_14_t expected;
} test_vec_t;

int main(void) {
    const test_vec_t tests[] = {
        {
            "t1",
            {3, 2},            // (3, 2) in Q16.0
            {24576, -4096},    // (1.5, -0.25) in Q2.14
            {81920, 36864}     // (5, 2.25) in Q19.14
        },
        {
            "t2",
            {-7, 4},           // (-7, 4) in Q16.0
            {-16384, 8192},    // (-1, 0.5) in Q2.14
            {81920, -122880}   // (5, -7.5) in Q19.14
        },
        {
            "t3",
            {32767, -32768},   // (32767, -32768) in Q16.0
            {8192, 8192},      // (0.5, 0.5) in Q2.14
            {536862720, -8192} // (32767.5, -0.5) in Q19.14
        },
        {
            "g01",
            {-32768, -32768},  // (-32768, -32768) in Q16.0
            {-32768, -32768},  // (-2.0, -2.0) in Q2.14
            {0, 2147483648LL}  // (0, 131072.0) in Q19.14
        },
        {
            "g02",
            {-32768, -32768},  // (-32768, -32768) in Q16.0
            {-32768, 32767},   // (-2.0, 1.999939) in Q2.14
            {2147450880LL, 32768} // (131070.0, 2.0) in Q19.14
        },
    };

    int fails = 0;
    const int count = (int)(sizeof(tests) / sizeof(tests[0]));

    for (int i = 0; i < count; ++i) {
        int64_t y_re = 0;
        int64_t y_im = 0;

        complex_mul_3dsp_eval(
            tests[i].a.re,
            tests[i].a.im,
            tests[i].b.re,
            tests[i].b.im,
            &y_re,
            &y_im
        );

        if (y_re != tests[i].expected.re || y_im != tests[i].expected.im) {
            ++fails;
            printf("FAIL %s: got (%lld, %lld), expected (%lld, %lld)\n",
                   tests[i].name,
                   (long long)y_re,
                   (long long)y_im,
                   (long long)tests[i].expected.re,
                   (long long)tests[i].expected.im);
        } else {
            printf("PASS %s\n", tests[i].name);
        }
    }

    printf("Summary: %d/%d passed\n", count - fails, count);
    return (fails == 0) ? 0 : 1;
}
