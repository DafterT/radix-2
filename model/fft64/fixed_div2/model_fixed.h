#ifndef FFT64_MODEL_FIXED_H
#define FFT64_MODEL_FIXED_H

#include <stdint.h>

#define FFT64_FIXED_SIZE 64

typedef struct {
    int16_t re;
    int16_t im;
} fft64_fixed_cpx_q16_0_t;

typedef struct {
    fft64_fixed_cpx_q16_0_t bins[FFT64_FIXED_SIZE];
} fft64_fixed_result_t;

fft64_fixed_result_t fft64_radix2_fixed_div2(
    const fft64_fixed_cpx_q16_0_t input[FFT64_FIXED_SIZE]
);

#endif
