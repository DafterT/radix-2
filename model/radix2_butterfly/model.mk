MODELS += radix2_butterfly_compare

RADIX2_BUTTERFLY_MODEL_DIR := $(THIS_DIR)/radix2_butterfly

MODEL_SRCS_radix2_butterfly_compare := \
	$(RADIX2_BUTTERFLY_MODEL_DIR)/fixed/radix2_butterfly_fixed_model.c \
	$(RADIX2_BUTTERFLY_MODEL_DIR)/reference/radix2_butterfly_reference_model.c \
	$(RADIX2_BUTTERFLY_MODEL_DIR)/tools/radix2_butterfly_compare.c
MODEL_INC_FLAGS_radix2_butterfly_compare := \
	-I$(RADIX2_BUTTERFLY_MODEL_DIR)/fixed \
	-I$(RADIX2_BUTTERFLY_MODEL_DIR)/reference
