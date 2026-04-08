#ifndef FFT64_MODEL_DOUBLE_H
#define FFT64_MODEL_DOUBLE_H

#define FFT64_SIZE 64
#define FFT64_TWIDDLE_COUNT (FFT64_SIZE / 2)

typedef struct {
    double re;
    double im;
} fft64_complex_t;

typedef struct {
    fft64_complex_t bins[FFT64_SIZE];
} fft64_result_t;

fft64_result_t fft64_radix2(const fft64_complex_t input[FFT64_SIZE]);

#endif
