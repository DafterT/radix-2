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

.PHONY: all mul fft fft_compare fft_fixed_compare print_twiddle clean

all: mul fft fft_fixed_compare print_twiddle

mul:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -Icomplex_mul_3dsp \
		complex_mul_3dsp/complex_mul_3dsp_model.c \
		complex_mul_3dsp/complex_mul_3dsp_test.c \
		-o $(MUL_EXE) $(LDLIBS)
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
	$(CC) $(CFLAGS) -Ifft64/fixed_sqrt2 -Ifft64/fixed_div2 -Ifft64/fixed_collect -Ifft64/reference \
		fft64/fixed_sqrt2/model_fixed.c \
		fft64/fixed_sqrt2/butterfly_fixed.c \
		fft64/fixed_div2/model_fixed.c \
		fft64/fixed_div2/butterfly_fixed.c \
		fft64/fixed_collect/model_fixed.c \
		fft64/fixed_collect/butterfly_fixed.c \
		fft64/reference/model_double.c \
		fft64/tools/compare_fixed.c \
		-o $(FFT_FIXED_COMPARE_EXE) $(LDLIBS)
	$(FFT_FIXED_COMPARE_EXE)

print_twiddle:
	printf '%s\n' "$(TWIDDLE_N)" | $(PYTHON) tools/print_twiddle_rom_data.py

clean:
	rm -rf $(BUILD_DIR)
