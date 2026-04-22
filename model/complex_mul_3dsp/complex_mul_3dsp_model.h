#ifndef COMPLEX_MUL_3DSP_MODEL_H
#define COMPLEX_MUL_3DSP_MODEL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void complex_mul_3dsp_eval(
    int16_t x_re,
    int16_t x_im,
    int16_t y_re,
    int16_t y_im,
    int64_t *out_re,
    int64_t *out_im
);

#ifdef __cplusplus
}
#endif

#endif
