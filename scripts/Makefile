PYTHON ?= python3
ROOT_DIR := $(abspath $(CURDIR)/..)
OUTPUT_DIR := $(CURDIR)/output
MODEL_LOG := $(OUTPUT_DIR)/fixed_stage_model.log
TB_LOG := $(OUTPUT_DIR)/fixed_stage_tb.log
COMPARE_SCRIPT := $(CURDIR)/compare_fixed_stage_outputs.py
STIM_SCRIPT := $(CURDIR)/generate_fixed_stage_stim.py

.PHONY: gen compare run-model run-tb clean

compare: run-model run-tb
	cd $(ROOT_DIR) && $(PYTHON) scripts/compare_fixed_stage_outputs.py $(MODEL_LOG) $(TB_LOG)

gen:
	mkdir -p $(OUTPUT_DIR)
	cd $(ROOT_DIR) && $(PYTHON) scripts/generate_fixed_stage_stim.py

run-model: gen
	mkdir -p $(OUTPUT_DIR)
	cd $(ROOT_DIR) && $(MAKE) --no-print-directory -C model run-stage > $(MODEL_LOG) 2>&1

run-tb: gen
	mkdir -p $(OUTPUT_DIR)
	cd $(ROOT_DIR) && $(MAKE) --no-print-directory -C tb run-stage > $(TB_LOG) 2>&1

clean:
	rm -rf $(OUTPUT_DIR)
