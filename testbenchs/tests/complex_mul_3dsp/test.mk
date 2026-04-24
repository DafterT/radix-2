TESTS += complex_mul_3dsp

RESET_CYCLES ?= 4

TEST_BACKEND_complex_mul_3dsp := verilator
TEST_TOP_complex_mul_3dsp := complex_mul_3dsp_dpi_tb
TEST_DIR_complex_mul_3dsp := $(TESTS_DIR)/complex_mul_3dsp
TEST_SV_SRCS_complex_mul_3dsp := \
	$(SV_PKG) \
	$(TEST_DIR_complex_mul_3dsp)/tb.sv \
	$(ROOT_DIR)/rtl/dsp48e2_slice_model.sv \
	$(ROOT_DIR)/rtl/complex_mul_3dsp.sv
TEST_DPI_WRAPPER_complex_mul_3dsp := $(TEST_DIR_complex_mul_3dsp)/dpi_wrapper.c
TEST_MODEL_SRCS_complex_mul_3dsp := $(ROOT_DIR)/model/complex_mul_3dsp/complex_mul_3dsp_model.c
TEST_MODEL_INC_FLAGS_complex_mul_3dsp := -I$(ROOT_DIR)/model/complex_mul_3dsp
TEST_VERILATOR_FLAGS_complex_mul_3dsp := -GRESET_CYCLES=$(RESET_CYCLES)
TEST_RUN_ARGS_complex_mul_3dsp := +infile=$(TEST_DIR_complex_mul_3dsp)/input.txt
