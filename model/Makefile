CC ?= gcc
PYTHON ?= python3
CFLAGS ?= -std=c11 -Wall -Wextra -O3
LDLIBS ?= -lm
BUILD_DIR := build
EXE_EXT := $(if $(filter Windows_NT,$(OS)),.exe,)
TWIDDLE_N ?= 64

MUL_EXE := $(BUILD_DIR)/mul$(EXE_EXT)
FFT_EXE := $(BUILD_DIR)/fft$(EXE_EXT)
FFT_COMPARE_EXE := $(BUILD_DIR)/fft_compare$(EXE_EXT)
FFT_FIXED_COMPARE_EXE := $(BUILD_DIR)/fft_fixed_compare$(EXE_EXT)
STAGE_FIXED_EXE := $(BUILD_DIR)/stage_fixed$(EXE_EXT)
STAGE_DOUBLE_EXE := $(BUILD_DIR)/stage_double$(EXE_EXT)
STAGE_COMPARE_EXE := $(BUILD_DIR)/stage_compare$(EXE_EXT)
STAGE_COMPARE_LOG := $(BUILD_DIR)/stage_compare.log

.PHONY: all mul fft fft_compare fft_fixed_compare stage_fixed stage_double stage_compare print_twiddle clean

all: mul fft stage_fixed stage_double stage_compare print_twiddle

mul:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) complex_mul_3dsp/complex_mul_3dsp_test.c -o $(MUL_EXE) $(LDLIBS)
	$(MUL_EXE)

fft:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -Ifft64/reference \
		fft64/reference/model_double.c \
		fft64/reference/double_main.c \
		-o $(FFT_EXE) $(LDLIBS)
	$(FFT_EXE)

fft_compare:
	mkdir -p $(BUILD_DIR)
	@test -f /usr/include/fftw3.h || \
		(printf '%s\n' 'fftw3.h not found in WSL. Install libfftw3-dev and rerun make -C model fft_compare.' && exit 1)
	$(CC) $(CFLAGS) -Ifft64/reference \
		fft64/reference/model_double.c \
		fft64/tools/compare_fftw.c \
		-o $(FFT_COMPARE_EXE) -lfftw3 $(LDLIBS)
	$(FFT_COMPARE_EXE)

fft_fixed_compare:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -Ifft64/fixed -Ifft64/reference \
		fft64/fixed/model_fixed.c \
		fft64/fixed/butterfly_fixed.c \
		fft64/reference/model_double.c \
		fft64/tools/compare_fixed.c \
		-o $(FFT_FIXED_COMPARE_EXE) $(LDLIBS)
	$(FFT_FIXED_COMPARE_EXE)

stage_fixed:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -Istage/fixed -Istage/reference \
		stage/fixed/model_fixed.c \
		stage/fixed/fixed_main.c \
		-o $(STAGE_FIXED_EXE) $(LDLIBS)
	$(STAGE_FIXED_EXE)

stage_double:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -Istage/reference \
		stage/reference/model_double.c \
		stage/reference/double_main.c \
		-o $(STAGE_DOUBLE_EXE) $(LDLIBS)
	$(STAGE_DOUBLE_EXE)

stage_compare:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -Istage/fixed -Istage/reference \
		stage/tools/compare.c \
		stage/fixed/model_fixed.c \
		stage/reference/model_double.c \
		-o $(STAGE_COMPARE_EXE) $(LDLIBS)
	$(STAGE_COMPARE_EXE) | tee $(STAGE_COMPARE_LOG)

print_twiddle:
	printf '%s\n' "$(TWIDDLE_N)" | $(PYTHON) tools/print_twiddle_rom_data.py

clean:
	rm -rf $(BUILD_DIR)
