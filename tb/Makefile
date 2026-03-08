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

# -------------------------------
# convergent_rounding_tb settings
# -------------------------------
TOP_ROUND := convergent_rounding_tb
TB_ROUND := $(THIS_DIR)/$(TOP_ROUND).sv
RTL_ROUND := $(ROOT_DIR)/rtl/convergent_rounding.sv
SIMV_ROUND := $(BUILD_DIR)/$(TOP_ROUND).vvp
VCD_ROUND ?= $(BUILD_DIR)/$(TOP_ROUND).vcd

IVFLAGS_ROUND := $(IVFLAGS_COMMON)

# -------------------------------
# symmetric_clip_tb settings
# -------------------------------
TOP_CLIP := symmetric_clip_tb
TB_CLIP := $(THIS_DIR)/$(TOP_CLIP).sv
RTL_CLIP := $(ROOT_DIR)/rtl/symmetric_clip.sv
SIMV_CLIP := $(BUILD_DIR)/$(TOP_CLIP).vvp
VCD_CLIP ?= $(BUILD_DIR)/$(TOP_CLIP).vcd

IVFLAGS_CLIP := $(IVFLAGS_COMMON)

.PHONY: all dsp mul round clip run-all wave-all build-dsp run-dsp wave-dsp build-mul run-mul wave-mul build-round run-round wave-round build-clip run-clip wave-clip run wave clean

all: run-all

dsp: run-dsp

mul: run-mul

round: run-round

clip: run-clip

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

build-round:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) $(IVFLAGS_ROUND) -o $(SIMV_ROUND) $(TB_ROUND) $(RTL_ROUND)

run-round: build-round
	$(VVP) $(SIMV_ROUND)

wave-round: build-round
	$(VVP) $(SIMV_ROUND) +dump +dumpfile=$(VCD_ROUND)
	@echo "VCD generated: $(VCD_ROUND)"

build-clip:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) $(IVFLAGS_CLIP) -o $(SIMV_CLIP) $(TB_CLIP) $(RTL_CLIP)

run-clip: build-clip
	$(VVP) $(SIMV_CLIP)

wave-clip: build-clip
	$(VVP) $(SIMV_CLIP) +dump +dumpfile=$(VCD_CLIP)
	@echo "VCD generated: $(VCD_CLIP)"

run-all: run-dsp run-mul run-round run-clip

wave-all: wave-dsp wave-mul wave-round wave-clip

# Backward compatibility with old single-test flow.
run: run-dsp

wave: wave-dsp

clean:
	rm -rf $(BUILD_DIR)
