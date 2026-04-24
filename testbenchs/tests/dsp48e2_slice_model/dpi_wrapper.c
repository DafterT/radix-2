#include <svdpi.h>
#include <stdio.h>

#include "dsp48e2_slice_model.h"

#ifdef __cplusplus
extern "C" {
#endif

long long dsp48e2_slice_model_dpi_model(
    svBit preadd_sub,
    svBit postadd_en,
    svBit postadd_sub,
    int a,
    int d,
    int b,
    long long c
) {

    return (long long)dsp48e2_slice_model_eval(
        (preadd_sub != 0U),
        (postadd_en != 0U),
        (postadd_sub != 0U),
        (int32_t)a,
        (int32_t)d,
        (int32_t)b,
        (int64_t)c
    );
}

#ifdef __cplusplus
}
#endif
