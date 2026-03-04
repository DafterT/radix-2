IVERILOG ?= iverilog
VVP ?= vvp

THIS_DIR := $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
ROOT_DIR := $(abspath $(THIS_DIR)/..)

BUILD_DIR ?= $(THIS_DIR)/build
IVFLAGS_COMMON := -g2012 -Wall

# -----------------------------
# DSP48E2_like_file_tb settings
# -----------------------------
TOP_DSP := DSP48E2_like_file_tb
TB_DSP := $(THIS_DIR)/$(TOP_DSP).sv
RTL_DSP := $(ROOT_DIR)/rtl/DSP48E2_like.sv
SIMV_DSP := $(BUILD_DIR)/$(TOP_DSP).vvp
VCD_DSP ?= $(BUILD_DIR)/$(TOP_DSP).vcd
INFILE_DSP ?= $(THIS_DIR)/input_vectors.txt

PREADD_SUB ?= 0
POSTADD_EN ?= 1
POSTADD_SUB ?= 0
RESET_CYCLES ?= 4
MUL_OUTPUT_OFFSET_CYCLES ?= 4

IVFLAGS_DSP := $(IVFLAGS_COMMON)
IVFLAGS_DSP += -P $(TOP_DSP).PREADD_SUB=$(PREADD_SUB)
IVFLAGS_DSP += -P $(TOP_DSP).POSTADD_EN=$(POSTADD_EN)
IVFLAGS_DSP += -P $(TOP_DSP).POSTADD_SUB=$(POSTADD_SUB)
IVFLAGS_DSP += -P $(TOP_DSP).RESET_CYCLES=$(RESET_CYCLES)

# -------------------------------
# complex_mul_3dsp_file_tb settings
# -------------------------------
TOP_MUL := complex_mul_3dsp_file_tb
TB_MUL := $(THIS_DIR)/$(TOP_MUL).sv
RTL_MUL := $(ROOT_DIR)/rtl/DSP48E2_like.sv $(ROOT_DIR)/rtl/complex_mul_3dsp.sv
SIMV_MUL := $(BUILD_DIR)/$(TOP_MUL).vvp
VCD_MUL ?= $(BUILD_DIR)/$(TOP_MUL).vcd
INFILE_MUL ?= $(THIS_DIR)/input_complex_vectors.txt

IVFLAGS_MUL := $(IVFLAGS_COMMON)
IVFLAGS_MUL += -P $(TOP_MUL).RESET_CYCLES=$(RESET_CYCLES)
IVFLAGS_MUL += -P $(TOP_MUL).OUTPUT_OFFSET_CYCLES=$(MUL_OUTPUT_OFFSET_CYCLES)

.PHONY: all dsp mul run-all wave-all build-dsp run-dsp wave-dsp build-mul run-mul wave-mul run wave clean

all: run-all

dsp: run-dsp

mul: run-mul

build-dsp:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) $(IVFLAGS_DSP) -o $(SIMV_DSP) $(TB_DSP) $(RTL_DSP)

run-dsp: build-dsp
	$(VVP) $(SIMV_DSP) +infile=$(INFILE_DSP)

wave-dsp: build-dsp
	$(VVP) $(SIMV_DSP) +infile=$(INFILE_DSP) +dump +dumpfile=$(VCD_DSP)
	@echo "VCD generated: $(VCD_DSP)"

build-mul:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) $(IVFLAGS_MUL) -o $(SIMV_MUL) $(TB_MUL) $(RTL_MUL)

run-mul: build-mul
	$(VVP) $(SIMV_MUL) +infile=$(INFILE_MUL)

wave-mul: build-mul
	$(VVP) $(SIMV_MUL) +infile=$(INFILE_MUL) +dump +dumpfile=$(VCD_MUL)
	@echo "VCD generated: $(VCD_MUL)"

run-all: run-dsp run-mul

wave-all: wave-dsp wave-mul

# Backward compatibility with old single-test flow.
run: run-dsp

wave: wave-dsp

clean:
	rm -rf $(BUILD_DIR)
