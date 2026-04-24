TESTS += radix2_butterfly

TEST_BACKEND_radix2_butterfly := iverilog
TEST_TOP_radix2_butterfly := radix2_butterfly_tb
TEST_DIR_radix2_butterfly := $(TESTS_DIR)/radix2_butterfly
TEST_SV_SRCS_radix2_butterfly := \
	$(SV_PKG) \
	$(TEST_DIR_radix2_butterfly)/tb.sv \
	$(ROOT_DIR)/rtl/dsp48e2_slice_model.sv \
	$(ROOT_DIR)/rtl/complex_requantize_q22_23_to_q16_0.sv \
	$(ROOT_DIR)/rtl/complex_mul_3dsp.sv \
	$(ROOT_DIR)/rtl/convergent_rounding.sv \
	$(ROOT_DIR)/rtl/delay_line_with_valid.sv \
	$(ROOT_DIR)/rtl/symmetric_saturate.sv \
	$(ROOT_DIR)/rtl/radix2_butterfly.sv
