TOP ?= DSP48E2_like_file_tb

IVERILOG ?= iverilog
VVP ?= vvp

THIS_DIR := $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
ROOT_DIR := $(abspath $(THIS_DIR)/..)

BUILD_DIR ?= $(THIS_DIR)/build
SIMV := $(BUILD_DIR)/$(TOP).vvp
VCD ?= $(BUILD_DIR)/$(TOP).vcd

RTL := $(ROOT_DIR)/rtl/DSP48E2_like.sv
TB := $(THIS_DIR)/$(TOP).sv

PREADD_SUB ?= 0
POSTADD_EN ?= 1
POSTADD_SUB ?= 0
RESET_CYCLES ?= 4
INFILE ?= $(THIS_DIR)/input_vectors.txt

IVFLAGS := -g2012 -Wall
IVFLAGS += -P $(TOP).PREADD_SUB=$(PREADD_SUB)
IVFLAGS += -P $(TOP).POSTADD_EN=$(POSTADD_EN)
IVFLAGS += -P $(TOP).POSTADD_SUB=$(POSTADD_SUB)
IVFLAGS += -P $(TOP).RESET_CYCLES=$(RESET_CYCLES)

.PHONY: all build run wave clean

all: wave

build:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) $(IVFLAGS) -o $(SIMV) $(TB) $(RTL)

run: build
	$(VVP) $(SIMV) +infile=$(INFILE)

wave: build
	$(VVP) $(SIMV) +infile=$(INFILE) +dump +dumpfile=$(VCD)
	@echo "VCD generated: $(VCD)"

clean:
	rm -rf $(BUILD_DIR)
