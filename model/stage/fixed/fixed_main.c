#include "radix2_fft_stage_model.h"

#include <stdlib.h>
#include <stdio.h>

#define FIXED_STAGE_STIM_FILE "../tb/input/fixed_stage_stim.txt"

typedef struct {
    int valid;
    int last;
    fixed_stage_cpx_q16_0_t a;
    fixed_stage_cpx_q16_0_t b;
} fixed_stage_stim_t;

static int fixed_stage_read_stim(FILE *stim_file, fixed_stage_stim_t *stim) {
    char line[256];

    while (fgets(line, sizeof(line), stim_file) != NULL) {
        int valid;
        int last;
        int a_re;
        int a_im;
        int b_re;
        int b_im;

        if (sscanf(line, "%d %d %d %d %d %d", &valid, &last, &a_re, &a_im, &b_re, &b_im) != 6) {
            continue;
        }

        stim->valid = valid;
        stim->last = last;
        stim->a.re = (int16_t)a_re;
        stim->a.im = (int16_t)a_im;
        stim->b.re = (int16_t)b_re;
        stim->b.im = (int16_t)b_im;
        return 1;
    }

    return 0;
}

int main(int argc, char **argv) {
    const char *stim_path = FIXED_STAGE_STIM_FILE;
    fixed_stage_model_t model = {0};

    if (argc > 1) {
        stim_path = argv[1];
    }

    FILE *stim_file = fopen(stim_path, "r");
    if (stim_file == NULL) {
        fprintf(stderr, "Failed to open stimulus file: %s\n", stim_path);
        return EXIT_FAILURE;
    }

    printf(
        " idx | valid | last |   a.re |   a.im |   b.re |   b.im | status | out.last | a_o.re | a_o.im | b_o.re | b_o.im\n"
    );
    printf(
        "-----+-------+------+--------+--------+--------+--------+--------+----------+--------+--------+--------+--------\n"
    );

    for (size_t i = 0;; ++i) {
        fixed_stage_stim_t stim;

        if (!fixed_stage_read_stim(stim_file, &stim)) {
            break;
        }

        if (!stim.valid) {
            printf(
                "%4zu | %5d | %4d | %6d | %6d | %6d | %6d | %-6s | %8s | %6s | %6s | %6s | %6s\n",
                i,
                stim.valid,
                stim.last,
                stim.a.re,
                stim.a.im,
                stim.b.re,
                stim.b.im,
                "SKIP",
                "-",
                "-",
                "-",
                "-",
                "-"
            );
            continue;
        }

        fixed_stage_output_t out = fixed_stage_step(&model, stim.a, stim.b, stim.last);

        printf(
            "%4zu | %5d | %4d | %6d | %6d | %6d | %6d | %-6s | %8d | %6d | %6d | %6d | %6d\n",
            i,
            stim.valid,
            stim.last,
            stim.a.re,
            stim.a.im,
            stim.b.re,
            stim.b.im,
            "RUN",
            out.last,
            out.a.re,
            out.a.im,
            out.b.re,
            out.b.im
        );
    }

    fclose(stim_file);
    return 0;
}
