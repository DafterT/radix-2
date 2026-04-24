TESTS += fft64_core

FRAMES ?= 32
SEED ?= 1
BACKOFF_DB ?= 12.0

TEST_BACKEND_fft64_core := verilator
TEST_TOP_fft64_core := fft64_core_dpi_tb
TEST_DIR_fft64_core := $(TESTS_DIR)/fft64_core
TEST_SV_SRCS_fft64_core := \
	$(SV_PKG) \
	$(TEST_DIR_fft64_core)/tb.sv \
	$(ROOT_DIR)/rtl/dsp48e2_slice_model.sv \
	$(ROOT_DIR)/rtl/complex_requantize_q22_23_to_q16_0.sv \
	$(ROOT_DIR)/rtl/complex_mul_3dsp.sv \
	$(ROOT_DIR)/rtl/convergent_rounding.sv \
	$(ROOT_DIR)/rtl/simple_dual_port_ram.sv \
	$(ROOT_DIR)/rtl/twiddle_rom.sv \
	$(ROOT_DIR)/rtl/radix2_butterfly.sv \
	$(ROOT_DIR)/rtl/fft64_controller.sv \
	$(ROOT_DIR)/rtl/fft64_core.sv \
	$(ROOT_DIR)/rtl/delay_line_with_valid.sv \
	$(ROOT_DIR)/rtl/symmetric_saturate.sv
TEST_DPI_WRAPPER_fft64_core := $(TEST_DIR_fft64_core)/dpi_wrapper.c
TEST_MODEL_SRCS_fft64_core := \
	$(ROOT_DIR)/model/fft64/fixed_sqrt2/model_fixed.c \
	$(ROOT_DIR)/model/fft64/fixed_sqrt2/butterfly_fixed.c \
	$(ROOT_DIR)/model/fft64/tools/fft64_white_noise.c
TEST_MODEL_INC_FLAGS_fft64_core := \
	-I$(ROOT_DIR)/model/fft64/fixed_sqrt2 \
	-I$(ROOT_DIR)/model/fft64/tools
TEST_RUN_ARGS_fft64_core := +frames=$(FRAMES) +seed=$(SEED) +backoff_db=$(BACKOFF_DB)
