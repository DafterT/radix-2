PYTHON ?= python3
SCRIPT := verify_dpi_complex_fixed_test.py
BUILD_DIR := build
BUILD_DIR_TARGET := $(BUILD_DIR)/
OUT := $(BUILD_DIR)/generated_test_cases.c

.PHONY: all build console file clean

all: build

build: file

$(BUILD_DIR_TARGET):
	mkdir -p $(BUILD_DIR)

console:
	$(PYTHON) $(SCRIPT)

file: $(SCRIPT) | $(BUILD_DIR_TARGET)
	$(PYTHON) $(SCRIPT) > $(OUT)
	@echo Written: $(OUT)

clean:
	$(RM) $(OUT)
	$(RM) -r $(BUILD_DIR)
