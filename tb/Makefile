IVERILOG ?= iverilog
VVP ?= vvp

THIS_DIR := $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
ROOT_DIR := $(abspath $(THIS_DIR)/..)

BUILD_DIR ?= $(THIS_DIR)/build
INPUT_DIR ?= $(THIS_DIR)/input
IVFLAGS_COMMON := -g2012 -Wall

# -----------------------------
# DSP48E2_like_file_tb settings
# -----------------------------
TOP_DSP := DSP48E2_like_file_tb
TB_DSP := $(THIS_DIR)/$(TOP_DSP).sv
RTL_DSP := $(ROOT_DIR)/rtl/DSP48E2_like.sv
SIMV_DSP := $(BUILD_DIR)/$(TOP_DSP).vvp
VCD_DSP ?= $(BUILD_DIR)/$(TOP_DSP).vcd
INFILE_DSP ?= $(INPUT_DIR)/input_vectors.txt

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
INFILE_MUL ?= $(INPUT_DIR)/input_complex_vectors.txt

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

# -------------------------------
# fft_twiddle_rom_tb settings
# -------------------------------
TOP_TW := fft_twiddle_rom_tb
TB_TW := $(THIS_DIR)/$(TOP_TW).sv
RTL_TW := $(ROOT_DIR)/rtl/fft_twiddle_rom.sv
SIMV_TW := $(BUILD_DIR)/$(TOP_TW).vvp
VCD_TW ?= $(BUILD_DIR)/$(TOP_TW).vcd

FFT_N ?= 64
FRAC_BITS ?= 14
TW_W ?= 16
TW_GEN_MODE ?= 0

IVFLAGS_TW := $(IVFLAGS_COMMON)
IVFLAGS_TW += -P $(TOP_TW).FFT_N=$(FFT_N)
IVFLAGS_TW += -P $(TOP_TW).FRAC_BITS=$(FRAC_BITS)
IVFLAGS_TW += -P $(TOP_TW).TW_W=$(TW_W)
IVFLAGS_TW += -P $(TOP_TW).TW_GEN_MODE=$(TW_GEN_MODE)

# -------------------------------
# radix2_top_tb settings
# -------------------------------
TOP_RADIX2 := radix2_top_tb
TB_RADIX2 := $(THIS_DIR)/$(TOP_RADIX2).sv
RTL_RADIX2 := $(ROOT_DIR)/rtl/DSP48E2_like.sv \
              $(ROOT_DIR)/rtl/complex_mul_3dsp.sv \
              $(ROOT_DIR)/rtl/convergent_rounding.sv \
              $(ROOT_DIR)/rtl/fft_twiddle_rom.sv \
              $(ROOT_DIR)/rtl/radix2_cu.sv \
              $(ROOT_DIR)/rtl/radix2_top.sv \
              $(ROOT_DIR)/rtl/shift_register_with_valid.sv \
              $(ROOT_DIR)/rtl/symmetric_clip.sv
SIMV_RADIX2 := $(BUILD_DIR)/$(TOP_RADIX2).vvp
VCD_RADIX2 ?= $(BUILD_DIR)/$(TOP_RADIX2).vcd

IVFLAGS_RADIX2 := $(IVFLAGS_COMMON)
IVFLAGS_RADIX2 += -P $(TOP_RADIX2).FFT_N=$(FFT_N)
IVFLAGS_RADIX2 += -P $(TOP_RADIX2).FRAC_BITS=14
IVFLAGS_RADIX2 += -P $(TOP_RADIX2).TW_W=16
IVFLAGS_RADIX2 += -P $(TOP_RADIX2).TW_GEN_MODE=$(TW_GEN_MODE)

.PHONY: all dsp mul round clip twiddle radix2 run-all wave-all build-dsp run-dsp wave-dsp build-mul run-mul wave-mul build-round run-round wave-round build-clip run-clip wave-clip build-tw run-tw wave-tw run-tw-alt build-radix2 run-radix2 wave-radix2 run-radix2-alt run-alt run wave clean

all: run-all

dsp: run-dsp

mul: run-mul

round: run-round

clip: run-clip

twiddle: run-tw

radix2: run-radix2

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

build-tw:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) $(IVFLAGS_TW) -o $(SIMV_TW) $(TB_TW) $(RTL_TW)

run-tw: build-tw
	$(VVP) $(SIMV_TW)

wave-tw: build-tw
	$(VVP) $(SIMV_TW) +dump +dumpfile=$(VCD_TW)
	@echo "VCD generated: $(VCD_TW)"

run-tw-alt:
	$(MAKE) run-tw TW_GEN_MODE=1

build-radix2:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) $(IVFLAGS_RADIX2) -o $(SIMV_RADIX2) $(TB_RADIX2) $(RTL_RADIX2)

run-radix2: build-radix2
	$(VVP) $(SIMV_RADIX2)

wave-radix2: build-radix2
	$(VVP) $(SIMV_RADIX2) +dump +dumpfile=$(VCD_RADIX2)
	@echo "VCD generated: $(VCD_RADIX2)"

run-radix2-alt:
	$(MAKE) run-radix2 TW_GEN_MODE=1

run-alt: run-tw-alt run-radix2-alt

run-all: run-dsp run-mul run-round run-clip run-tw run-radix2

wave-all: wave-dsp wave-mul wave-round wave-clip wave-tw wave-radix2

# Backward compatibility with old single-test flow.
run: run-dsp

wave: wave-dsp

clean:
	rm -rf $(BUILD_DIR)
