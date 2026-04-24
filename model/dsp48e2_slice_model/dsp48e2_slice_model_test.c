#include "dsp48e2_slice_model.h"

#include <stdio.h>

typedef struct {
    const char *name;
    int preadd_sub;
    int postadd_en;
    int postadd_sub;
    int32_t a;
    int32_t d;
    int32_t b;
    int64_t c;
    int64_t expected;
} dsp48e2_slice_model_test_vec_t;

int main(void) {
    const dsp48e2_slice_model_test_vec_t tests[] = {
        {"mul_only", 0, 0, 0, 3, 5, 7, 11, 56},
        {"postadd", 1, 1, 0, 4, 10, -3, 100, 82},
        {"postsub", 0, 1, 1, 5, -2, 4, 20, 8},
    };
    const int count = (int)(sizeof(tests) / sizeof(tests[0]));
    int fails = 0;

    for (int i = 0; i < count; ++i) {
        int64_t actual = dsp48e2_slice_model_eval(
            tests[i].preadd_sub,
            tests[i].postadd_en,
            tests[i].postadd_sub,
            tests[i].a,
            tests[i].d,
            tests[i].b,
            tests[i].c
        );

        if (actual != tests[i].expected) {
            ++fails;
            printf(
                "FAIL %s: got %lld, expected %lld\n",
                tests[i].name,
                (long long)actual,
                (long long)tests[i].expected
            );
        } else {
            printf("PASS %s\n", tests[i].name);
        }
    }

    printf("Summary: %d/%d passed\n", count - fails, count);
    return (fails == 0) ? 0 : 1;
}
