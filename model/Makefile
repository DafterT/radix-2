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

.PHONY: all build run build-fft64 run-fft64 clean

all: build

build: $(TARGET)

build-fft64: $(FFT64_TARGET)

$(BUILD_DIR_TARGET):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(SRC) | $(BUILD_DIR_TARGET)
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

$(FFT64_TARGET): $(FFT64_SRC) | $(BUILD_DIR_TARGET)
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

run: build
	$(TARGET)

run-fft64: build-fft64
	$(FFT64_TARGET)

clean:
	$(RM) $(TARGET)
	$(RM) $(FFT64_TARGET)
	$(RM) -r $(BUILD_DIR)
