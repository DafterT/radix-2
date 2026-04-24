MODELS += fft64_core_reference fft64_core_fixed_compare twiddle_rom_data
OPTIONAL_MODELS += fft64_core_reference_compare_fftw

FFT64_CORE_MODEL_DIR := $(THIS_DIR)/fft64_core
TWIDDLE_N ?= 64

MODEL_SRCS_fft64_core_reference := \
	$(FFT64_CORE_MODEL_DIR)/reference/fft64_core_reference_model.c \
	$(FFT64_CORE_MODEL_DIR)/reference/fft64_core_reference_main.c
MODEL_INC_FLAGS_fft64_core_reference := \
	-I$(FFT64_CORE_MODEL_DIR) \
	-I$(FFT64_CORE_MODEL_DIR)/reference

MODEL_SRCS_fft64_core_reference_compare_fftw := \
	$(FFT64_CORE_MODEL_DIR)/reference/fft64_core_reference_model.c \
	$(FFT64_CORE_MODEL_DIR)/tools/fft64_core_reference_compare_fftw.c
MODEL_INC_FLAGS_fft64_core_reference_compare_fftw := \
	-I$(FFT64_CORE_MODEL_DIR) \
	-I$(FFT64_CORE_MODEL_DIR)/reference
MODEL_LDLIBS_fft64_core_reference_compare_fftw := -lfftw3
MODEL_PREBUILD_fft64_core_reference_compare_fftw := check-fftw3

MODEL_SRCS_fft64_core_fixed_compare := \
	$(FFT64_CORE_MODEL_DIR)/fixed_sqrt2/fft64_core_fixed_sqrt2_model.c \
	$(FFT64_CORE_MODEL_DIR)/fixed_sqrt2/fft64_core_fixed_sqrt2_butterfly.c \
	$(FFT64_CORE_MODEL_DIR)/fixed_div2/fft64_core_fixed_div2_model.c \
	$(FFT64_CORE_MODEL_DIR)/fixed_div2/fft64_core_fixed_div2_butterfly.c \
	$(FFT64_CORE_MODEL_DIR)/fixed_collect/fft64_core_fixed_collect_model.c \
	$(FFT64_CORE_MODEL_DIR)/fixed_collect/fft64_core_fixed_collect_butterfly.c \
	$(FFT64_CORE_MODEL_DIR)/reference/fft64_core_reference_model.c \
	$(FFT64_CORE_MODEL_DIR)/tools/fft64_core_fixed_compare.c
MODEL_INC_FLAGS_fft64_core_fixed_compare := \
	-I$(FFT64_CORE_MODEL_DIR) \
	-I$(FFT64_CORE_MODEL_DIR)/fixed_sqrt2 \
	-I$(FFT64_CORE_MODEL_DIR)/fixed_div2 \
	-I$(FFT64_CORE_MODEL_DIR)/fixed_collect \
	-I$(FFT64_CORE_MODEL_DIR)/reference

MODEL_BACKEND_twiddle_rom_data := command
MODEL_RUN_CMD_twiddle_rom_data := printf '%s\n' "$(TWIDDLE_N)" | $(PYTHON) $(THIS_DIR)/tools/print_twiddle_rom_data.py

.PHONY: check-fftw3
check-fftw3:
	@test -f /usr/include/fftw3.h || \
		(printf '%s\n' 'fftw3.h not found in WSL. Install libfftw3-dev and rerun make -C model run-fft64_core_reference_compare_fftw.' && exit 1)
