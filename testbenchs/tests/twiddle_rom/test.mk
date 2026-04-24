TESTS += twiddle_rom

FFT_N ?= 64
TW_W ?= 16

TEST_BACKEND_twiddle_rom := iverilog
TEST_TOP_twiddle_rom := twiddle_rom_tb
TEST_DIR_twiddle_rom := $(TESTS_DIR)/twiddle_rom
TEST_SV_SRCS_twiddle_rom := \
	$(SV_PKG) \
	$(TEST_DIR_twiddle_rom)/tb.sv \
	$(ROOT_DIR)/rtl/twiddle_rom.sv
TEST_IVERILOG_FLAGS_twiddle_rom := \
	-P $(TEST_TOP_twiddle_rom).FFT_N=$(FFT_N) \
	-P $(TEST_TOP_twiddle_rom).TW_W=$(TW_W)
