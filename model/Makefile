CC ?= gcc
CFLAGS ?= -std=c11 -Wall -Wextra -O3
BUILD_DIR := build
BUILD_DIR_TARGET := $(BUILD_DIR)/
TARGET_NAME ?= dpi_complex_fixed_test
EXE_EXT := $(if $(filter Windows_NT,$(OS)),.exe,)
TARGET := $(BUILD_DIR)/$(TARGET_NAME)$(EXE_EXT)
SRC := dpi_complex_fixed_test.c

.PHONY: all build run clean

all: build

build: $(TARGET)

$(BUILD_DIR_TARGET):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(SRC) | $(BUILD_DIR_TARGET)
	$(CC) $(CFLAGS) $< -o $@

run: build
	$(TARGET)

clean:
	$(RM) $(TARGET)
	$(RM) -r $(BUILD_DIR)
