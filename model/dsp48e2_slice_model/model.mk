MODELS += dsp48e2_slice_model

DSP48E2_SLICE_MODEL_DIR := $(THIS_DIR)/dsp48e2_slice_model

MODEL_SRCS_dsp48e2_slice_model := \
	$(DSP48E2_SLICE_MODEL_DIR)/dsp48e2_slice_model.c \
	$(DSP48E2_SLICE_MODEL_DIR)/dsp48e2_slice_model_test.c
MODEL_INC_FLAGS_dsp48e2_slice_model := -I$(DSP48E2_SLICE_MODEL_DIR)
