CC ?= gcc
CFLAGS ?= -std=c11 -Wall -Wextra -O3
PYTHON ?= python3
BUILD_DIR := build
BUILD_DIR_TARGET := $(BUILD_DIR)/
TARGET_NAME ?= dpi_complex_fixed_test
EXE_EXT := $(if $(filter Windows_NT,$(OS)),.exe,)
TARGET := $(BUILD_DIR)/$(TARGET_NAME)$(EXE_EXT)
SRC := dpi_complex_fixed_test.c
RADIX2_IDEAL_SCRIPT := radix2_top_ideal_model.py

.PHONY: all build run radix2-ideal run-radix2-ideal clean

all: build

build: $(TARGET)

$(BUILD_DIR_TARGET):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(SRC) | $(BUILD_DIR_TARGET)
	$(CC) $(CFLAGS) $< -o $@

run: build
	$(TARGET)

radix2-ideal:
	$(PYTHON) $(RADIX2_IDEAL_SCRIPT)

run-radix2-ideal: radix2-ideal

clean:
	$(RM) $(TARGET)
	$(RM) -r $(BUILD_DIR)
