MODELS += complex_mul_3dsp

COMPLEX_MUL_3DSP_DIR := $(THIS_DIR)/complex_mul_3dsp

MODEL_SRCS_complex_mul_3dsp := \
	$(COMPLEX_MUL_3DSP_DIR)/complex_mul_3dsp_model.c \
	$(COMPLEX_MUL_3DSP_DIR)/complex_mul_3dsp_test.c
MODEL_INC_FLAGS_complex_mul_3dsp := -I$(COMPLEX_MUL_3DSP_DIR)
