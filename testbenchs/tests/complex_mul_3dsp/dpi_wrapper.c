#include <svdpi.h>

#include "complex_mul_3dsp_model.h"

#ifdef __cplusplus
extern "C" {
#endif

void complex_mul_3dsp_dpi_model(
    int x_re,
    int x_im,
    int y_re,
    int y_im,
    long long *out_re,
    long long *out_im
) {
    int64_t model_re;
    int64_t model_im;

    complex_mul_3dsp_eval(
        (int16_t)x_re,
        (int16_t)x_im,
        (int16_t)y_re,
        (int16_t)y_im,
        &model_re,
        &model_im
    );

    *out_re = (long long)model_re;
    *out_im = (long long)model_im;
}

#ifdef __cplusplus
}
#endif
