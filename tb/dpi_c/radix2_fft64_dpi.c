#include <svdpi.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "model_fixed.h"
#include "fft64_white_noise.h"

#ifdef __cplusplus
extern "C" {
#endif

static void radix2_fft64_dpi_require_size(
    const svOpenArrayHandle handle,
    const char *array_name
) {
    if (svSize(handle, 1) != FFT64_FIXED_SIZE) {
        fprintf(
            stderr,
            "radix2_fft64_dpi: %s size must be %d, got %d\n",
            array_name,
            FFT64_FIXED_SIZE,
            svSize(handle, 1)
        );
        abort();
    }
}

static int16_t radix2_fft64_dpi_read_shortint(
    const svOpenArrayHandle handle,
    int index
) {
    const int16_t *value_ptr = (const int16_t *)svGetArrElemPtr1(handle, index);

    return *value_ptr;
}

static void radix2_fft64_dpi_write_shortint(
    const svOpenArrayHandle handle,
    int index,
    int16_t value
) {
    int16_t *value_ptr = (int16_t *)svGetArrElemPtr1(handle, index);

    *value_ptr = value;
}

void radix2_fft64_dpi_generate_frame(
    int seed,
    int frame_index,
    double backoff_db,
    const svOpenArrayHandle re_out,
    const svOpenArrayHandle im_out
) {
    fft64_fixed_cpx_q16_0_t frame[FFT64_FIXED_SIZE];

    radix2_fft64_dpi_require_size(re_out, "re_out");
    radix2_fft64_dpi_require_size(im_out, "im_out");

    fft64_white_noise_generate_frame(
        frame,
        (uint32_t)seed,
        (uint32_t)frame_index,
        backoff_db
    );

    for (int i = 0; i < FFT64_FIXED_SIZE; ++i) {
        radix2_fft64_dpi_write_shortint(re_out, i, frame[i].re);
        radix2_fft64_dpi_write_shortint(im_out, i, frame[i].im);
    }
}

void radix2_fft64_dpi_model_frame(
    const svOpenArrayHandle in_re,
    const svOpenArrayHandle in_im,
    const svOpenArrayHandle out_re,
    const svOpenArrayHandle out_im
) {
    fft64_fixed_cpx_q16_0_t input[FFT64_FIXED_SIZE];
    fft64_fixed_result_t result;

    radix2_fft64_dpi_require_size(in_re, "in_re");
    radix2_fft64_dpi_require_size(in_im, "in_im");
    radix2_fft64_dpi_require_size(out_re, "out_re");
    radix2_fft64_dpi_require_size(out_im, "out_im");

    for (int i = 0; i < FFT64_FIXED_SIZE; ++i) {
        input[i].re = radix2_fft64_dpi_read_shortint(in_re, i);
        input[i].im = radix2_fft64_dpi_read_shortint(in_im, i);
    }

    result = fft64_radix2_fixed(input);

    for (int i = 0; i < FFT64_FIXED_SIZE; ++i) {
        radix2_fft64_dpi_write_shortint(out_re, i, result.bins[i].re);
        radix2_fft64_dpi_write_shortint(out_im, i, result.bins[i].im);
    }
}

#ifdef __cplusplus
}
#endif
