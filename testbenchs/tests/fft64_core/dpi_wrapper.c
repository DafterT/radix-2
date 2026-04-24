#include <svdpi.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "fft64_core_fixed_sqrt2_model.h"
#include "fft64_core_white_noise.h"

#ifdef __cplusplus
extern "C" {
#endif

static void fft64_core_dpi_require_size(
    const svOpenArrayHandle handle,
    const char *array_name
) {
    if (svSize(handle, 1) != FFT64_CORE_SIZE) {
        fprintf(
            stderr,
            "fft64_core_dpi: %s size must be %d, got %d\n",
            array_name,
            FFT64_CORE_SIZE,
            svSize(handle, 1)
        );
        abort();
    }
}

static int16_t fft64_core_dpi_read_shortint(
    const svOpenArrayHandle handle,
    int index
) {
    const int16_t *value_ptr = (const int16_t *)svGetArrElemPtr1(handle, index);

    return *value_ptr;
}

static void fft64_core_dpi_write_shortint(
    const svOpenArrayHandle handle,
    int index,
    int16_t value
) {
    int16_t *value_ptr = (int16_t *)svGetArrElemPtr1(handle, index);

    *value_ptr = value;
}

void fft64_core_dpi_generate_frame(
    int seed,
    int frame_index,
    double backoff_db,
    const svOpenArrayHandle re_out,
    const svOpenArrayHandle im_out
) {
    fft64_core_cpx_q16_0_t frame[FFT64_CORE_SIZE];

    fft64_core_dpi_require_size(re_out, "re_out");
    fft64_core_dpi_require_size(im_out, "im_out");

    fft64_core_white_noise_generate_frame(
        frame,
        (uint32_t)seed,
        (uint32_t)frame_index,
        backoff_db
    );

    for (int i = 0; i < FFT64_CORE_SIZE; ++i) {
        fft64_core_dpi_write_shortint(re_out, i, frame[i].re);
        fft64_core_dpi_write_shortint(im_out, i, frame[i].im);
    }
}

void fft64_core_dpi_model_frame(
    const svOpenArrayHandle in_re,
    const svOpenArrayHandle in_im,
    const svOpenArrayHandle out_re,
    const svOpenArrayHandle out_im
) {
    fft64_core_cpx_q16_0_t input[FFT64_CORE_SIZE];
    fft64_core_fixed_result_t result;

    fft64_core_dpi_require_size(in_re, "in_re");
    fft64_core_dpi_require_size(in_im, "in_im");
    fft64_core_dpi_require_size(out_re, "out_re");
    fft64_core_dpi_require_size(out_im, "out_im");

    for (int i = 0; i < FFT64_CORE_SIZE; ++i) {
        input[i].re = fft64_core_dpi_read_shortint(in_re, i);
        input[i].im = fft64_core_dpi_read_shortint(in_im, i);
    }

    result = fft64_core_fixed_sqrt2_eval(input);

    for (int i = 0; i < FFT64_CORE_SIZE; ++i) {
        fft64_core_dpi_write_shortint(out_re, i, result.bins[i].re);
        fft64_core_dpi_write_shortint(out_im, i, result.bins[i].im);
    }
}

#ifdef __cplusplus
}
#endif
