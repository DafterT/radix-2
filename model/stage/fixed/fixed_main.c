#include "radix2_fft_stage_model.h"

#include <stddef.h>
#include <stdio.h>

typedef struct {
    int valid;
    int last;
    fixed_stage_cpx_q16_0_t a;
    fixed_stage_cpx_q16_0_t b;
} fixed_stage_stim_t;

static const fixed_stage_stim_t g_stage_tb_stim[] = {
    {
        .valid = 1,
        .last = 0,
        .a = { .re = 10, .im = 2 },
        .b = { .re = 3, .im = 4 }
    },
    {
        .valid = 1,
        .last = 0,
        .a = { .re = 7, .im = -3 },
        .b = { .re = -2, .im = 1 }
    },
    {
        .valid = 1,
        .last = 1,
        .a = { .re = -8, .im = 5 },
        .b = { .re = 2, .im = -6 }
    },
    {
        .valid = 0,
        .last = 0,
        .a = { .re = 0, .im = 0 },
        .b = { .re = 0, .im = 0 }
    },
    {
        .valid = 1,
        .last = 0,
        .a = { .re = -1, .im = -1 },
        .b = { .re = 2, .im = 2 }
    },
    {
        .valid = 1,
        .last = 1,
        .a = { .re = 4, .im = 1 },
        .b = { .re = 1, .im = -3 }
    }
};

int main(void) {
    fixed_stage_model_t model = {0};
    size_t stim_count = sizeof(g_stage_tb_stim) / sizeof(g_stage_tb_stim[0]);

    printf(
        " idx | valid | last |   a.re |   a.im |   b.re |   b.im | status | out.last | a_o.re | a_o.im | b_o.re | b_o.im\n"
    );
    printf(
        "-----+-------+------+--------+--------+--------+--------+--------+----------+--------+--------+--------+--------\n"
    );

    for (size_t i = 0; i < stim_count; ++i) {
        const fixed_stage_stim_t *stim = &g_stage_tb_stim[i];

        if (!stim->valid) {
            printf(
                "%4zu | %5d | %4d | %6d | %6d | %6d | %6d | %-6s | %8s | %6s | %6s | %6s | %6s\n",
                i,
                stim->valid,
                stim->last,
                stim->a.re,
                stim->a.im,
                stim->b.re,
                stim->b.im,
                "SKIP",
                "-",
                "-",
                "-",
                "-",
                "-"
            );
            continue;
        }

        fixed_stage_output_t out = fixed_stage_step(&model, stim->a, stim->b, stim->last);

        printf(
            "%4zu | %5d | %4d | %6d | %6d | %6d | %6d | %-6s | %8d | %6d | %6d | %6d | %6d\n",
            i,
            stim->valid,
            stim->last,
            stim->a.re,
            stim->a.im,
            stim->b.re,
            stim->b.im,
            "RUN",
            out.last,
            out.a.re,
            out.a.im,
            out.b.re,
            out.b.im
        );
    }

    return 0;
}
