#ifndef DSP48E2_SLICE_MODEL_H
#define DSP48E2_SLICE_MODEL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int64_t dsp48e2_slice_model_eval(
    int preadd_sub,
    int postadd_en,
    int postadd_sub,
    int32_t a_in,
    int32_t d_in,
    int32_t b_in,
    int64_t c_in
);

#ifdef __cplusplus
}
#endif

#endif
