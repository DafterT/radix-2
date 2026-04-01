CC ?= gcc
PYTHON ?= python3
CFLAGS ?= -std=c11 -Wall -Wextra -O3
LDLIBS ?= -lm
BUILD_DIR := build
EXE_EXT := $(if $(filter Windows_NT,$(OS)),.exe,)
TWIDDLE_N ?= 64

MUL_EXE := $(BUILD_DIR)/mul$(EXE_EXT)
FFT_EXE := $(BUILD_DIR)/fft$(EXE_EXT)
STAGE_FIXED_EXE := $(BUILD_DIR)/stage_fixed$(EXE_EXT)
STAGE_DOUBLE_EXE := $(BUILD_DIR)/stage_double$(EXE_EXT)
STAGE_COMPARE_EXE := $(BUILD_DIR)/stage_compare$(EXE_EXT)

.PHONY: all mul fft stage_fixed stage_double stage_compare print_twiddle

all: mul fft stage_fixed stage_double stage_compare print_twiddle

mul:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) complex_mul_3dsp/complex_mul_3dsp_test.c -o $(MUL_EXE) $(LDLIBS)
	$(MUL_EXE)

fft:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) fft64/radix2_fft64_model.c -o $(FFT_EXE) $(LDLIBS)
	$(FFT_EXE)

stage_fixed:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -Istage/fixed -Istage/reference \
		stage/fixed/fft_stage_model_fixed.c \
		stage/fixed/fixed_main.c \
		-o $(STAGE_FIXED_EXE) $(LDLIBS)
	$(STAGE_FIXED_EXE)

stage_double:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -Istage/reference \
		stage/reference/fft_stage_model_double.c \
		stage/reference/double_main.c \
		-o $(STAGE_DOUBLE_EXE) $(LDLIBS)
	$(STAGE_DOUBLE_EXE)

stage_compare:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -Istage/fixed -Istage/reference \
		stage/tools/radix2_fft_stage_compare.c \
		stage/fixed/fft_stage_model_fixed.c \
		stage/reference/fft_stage_model_double.c \
		-o $(STAGE_COMPARE_EXE) $(LDLIBS)
	$(STAGE_COMPARE_EXE)

print_twiddle:
	printf '%s\n' "$(TWIDDLE_N)" | $(PYTHON) tools/print_twiddle_rom_data.py
