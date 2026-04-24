#include "model_double.h"

#include <stdio.h>
#include <stdlib.h>

typedef struct {
    int valid;
    int last;
    double_stage_cpx_t a;
    double_stage_cpx_t b;
} double_stage_stim_t;

static int double_stage_read_stim(FILE *stim_file, double_stage_stim_t *stim) {
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
        stim->a.re = (double)a_re;
        stim->a.im = (double)a_im;
        stim->b.re = (double)b_re;
        stim->b.im = (double)b_im;
        return 1;
    }

    return 0;
}

int main(int argc, char **argv) {
    const char *stim_path = NULL;
    double_stage_model_t model = {0};

    if (argc > 1) {
        stim_path = argv[1];
    } else {
        fprintf(stderr, "Usage: %s <stimulus-file>\n", argv[0]);
        return EXIT_FAILURE;
    }

    FILE *stim_file = fopen(stim_path, "r");
    if (stim_file == NULL) {
        fprintf(stderr, "Failed to open stimulus file: %s\n", stim_path);
        return EXIT_FAILURE;
    }

    printf(
        " idx | valid | last |   a.re |   a.im |   b.re |   b.im | status | out.last |"
        "        a_o.re |        a_o.im |        b_o.re |        b_o.im\n"
    );
    printf(
        "-----+-------+------+--------+--------+--------+--------+--------+----------+"
        "---------------+---------------+---------------+---------------\n"
    );

    for (size_t i = 0;; ++i) {
        double_stage_stim_t stim;

        if (!double_stage_read_stim(stim_file, &stim)) {
            break;
        }

        if (!stim.valid) {
            printf(
                "%4zu | %5d | %4d | %6.0f | %6.0f | %6.0f | %6.0f | %-6s | %8s | %13s | %13s | %13s | %13s\n",
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

        double_stage_output_t out = double_stage_step(&model, stim.a, stim.b, stim.last);

        printf(
            "%4zu | %5d | %4d | %6.0f | %6.0f | %6.0f | %6.0f | %-6s | %8d | %13.6f | %13.6f | %13.6f | %13.6f\n",
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
