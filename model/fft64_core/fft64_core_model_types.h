#ifndef FFT64_CORE_MODEL_TYPES_H
#define FFT64_CORE_MODEL_TYPES_H

#include <stdint.h>

#define FFT64_CORE_SIZE 64
#define FFT64_CORE_TWIDDLE_COUNT (FFT64_CORE_SIZE / 2)

typedef struct {
    double re;
    double im;
} fft64_core_complex_t;

typedef struct {
    fft64_core_complex_t bins[FFT64_CORE_SIZE];
} fft64_core_result_t;

typedef struct {
    int16_t re;
    int16_t im;
} fft64_core_cpx_q16_0_t;

typedef struct {
    int32_t re;
    int32_t im;
} fft64_core_cpx_q22_0_t;

typedef struct {
    fft64_core_cpx_q16_0_t bins[FFT64_CORE_SIZE];
} fft64_core_fixed_result_t;

#endif
