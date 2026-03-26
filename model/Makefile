CC ?= gcc
CFLAGS ?= -std=c11 -Wall -Wextra -O3
LDLIBS ?= -lm
BUILD_DIR := build
BUILD_DIR_TARGET := $(BUILD_DIR)/
TARGET_NAME ?= dpi_complex_fixed_test
EXE_EXT := $(if $(filter Windows_NT,$(OS)),.exe,)
TARGET := $(BUILD_DIR)/$(TARGET_NAME)$(EXE_EXT)
SRC := dpi_complex_fixed_test.c
FFT64_TARGET_NAME := radix2_fft64_model
FFT64_SRC := radix2_fft64_model.c
FFT64_TARGET := $(BUILD_DIR)/$(FFT64_TARGET_NAME)$(EXE_EXT)
FFT_STAGE_TARGET_NAME := radix2_fft_stage_model
FFT_STAGE_SRC := radix2_fft_stage_model.c
FFT_STAGE_TARGET := $(BUILD_DIR)/$(FFT_STAGE_TARGET_NAME)$(EXE_EXT)
FFT_STAGE_DOUBLE_TARGET_NAME := radix2_fft_stage_model_double
FFT_STAGE_DOUBLE_SRC := radix2_fft_stage_model_double.c
FFT_STAGE_DOUBLE_TARGET := $(BUILD_DIR)/$(FFT_STAGE_DOUBLE_TARGET_NAME)$(EXE_EXT)
FFT_STAGE_COMPARE_TARGET_NAME := radix2_fft_stage_compare
FFT_STAGE_COMPARE_SRC := radix2_fft_stage_compare.c
FFT_STAGE_COMPARE_TARGET := $(BUILD_DIR)/$(FFT_STAGE_COMPARE_TARGET_NAME)$(EXE_EXT)
FFT_STAGE_COMPARE_CPPFLAGS := -DFIXED_STAGE_MODEL_NO_MAIN -DDOUBLE_STAGE_MODEL_NO_MAIN

.PHONY: all build run build-fft64 run-fft64 build-stage run-stage build-stage-double run-stage-double build-stage-compare run-stage-compare clean

all: build

build: $(TARGET)

build-fft64: $(FFT64_TARGET)

build-stage: $(FFT_STAGE_TARGET)

build-stage-double: $(FFT_STAGE_DOUBLE_TARGET)

build-stage-compare: $(FFT_STAGE_COMPARE_TARGET)

$(BUILD_DIR_TARGET):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(SRC) | $(BUILD_DIR_TARGET)
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

$(FFT64_TARGET): $(FFT64_SRC) | $(BUILD_DIR_TARGET)
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

$(FFT_STAGE_TARGET): $(FFT_STAGE_SRC) | $(BUILD_DIR_TARGET)
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

$(FFT_STAGE_DOUBLE_TARGET): $(FFT_STAGE_DOUBLE_SRC) | $(BUILD_DIR_TARGET)
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

$(FFT_STAGE_COMPARE_TARGET): $(FFT_STAGE_COMPARE_SRC) $(FFT_STAGE_SRC) $(FFT_STAGE_DOUBLE_SRC) | $(BUILD_DIR_TARGET)
	$(CC) $(CFLAGS) $(FFT_STAGE_COMPARE_CPPFLAGS) $(FFT_STAGE_COMPARE_SRC) $(FFT_STAGE_SRC) $(FFT_STAGE_DOUBLE_SRC) -o $@ $(LDLIBS)

run: build
	$(TARGET)

run-fft64: build-fft64
	$(FFT64_TARGET)

run-stage: build-stage
	$(FFT_STAGE_TARGET)

run-stage-double: build-stage-double
	$(FFT_STAGE_DOUBLE_TARGET)

run-stage-compare: build-stage-compare
	$(FFT_STAGE_COMPARE_TARGET)

clean:
	$(RM) $(TARGET)
	$(RM) $(FFT64_TARGET)
	$(RM) $(FFT_STAGE_TARGET)
	$(RM) $(FFT_STAGE_DOUBLE_TARGET)
	$(RM) $(FFT_STAGE_COMPARE_TARGET)
	$(RM) -r $(BUILD_DIR)
