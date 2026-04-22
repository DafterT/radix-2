VERILATOR ?= verilator
CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11
VERILATOR_DPI_INC ?= /usr/share/verilator/include/vltstd

THIS_DIR := $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
TB_DIR := $(abspath $(THIS_DIR)/..)
ROOT_DIR := $(abspath $(TB_DIR)/..)
BUILD_DIR := $(TB_DIR)/build
OBJ_DIR := $(THIS_DIR)/obj_dir

TOP := DSP48E2_like_file_tb
TB_SRC := $(TB_DIR)/$(TOP).sv
RTL_SRC := $(ROOT_DIR)/rtl/DSP48E2_like.sv
MODEL_DIR := $(ROOT_DIR)/model/dsp48e2_like
MODEL_SRC := $(MODEL_DIR)/dsp48e2_like_model.c
DPI_WRAPPER_SRC := $(THIS_DIR)/dsp48e2_like_dpi.c
DPI_WRAPPER_HDR := $(THIS_DIR)/dsp48e2_like_dpi.h
MODEL_OBJ := $(OBJ_DIR)/dsp48e2_like_model.o
DPI_WRAPPER_OBJ := $(OBJ_DIR)/dsp48e2_like_dpi.o

PREADD_SUB ?= 0
POSTADD_EN ?= 1
POSTADD_SUB ?= 0

INFILE ?= $(TB_DIR)/input/input_vectors.txt
DUMPFILE ?= $(BUILD_DIR)/$(TOP).vcd

VERILATOR_FLAGS := --binary --sv --timing --trace -Wall -Wno-fatal
VERILATOR_FLAGS += --top-module $(TOP)
VERILATOR_FLAGS += --Mdir $(OBJ_DIR)
VERILATOR_FLAGS += -GPREADD_SUB=$(PREADD_SUB)
VERILATOR_FLAGS += -GPOSTADD_EN=$(POSTADD_EN)
VERILATOR_FLAGS += -GPOSTADD_SUB=$(POSTADD_SUB)

RUN_ARGS := +infile=$(INFILE)

.PHONY: all build run wave clean

all: run

build:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(OBJ_DIR)
	$(CC) $(CFLAGS) -I$(MODEL_DIR) -c $(MODEL_SRC) -o $(MODEL_OBJ)
	$(CC) $(CFLAGS) -I$(THIS_DIR) -I$(MODEL_DIR) -I$(VERILATOR_DPI_INC) -c $(DPI_WRAPPER_SRC) -o $(DPI_WRAPPER_OBJ)
	$(VERILATOR) $(VERILATOR_FLAGS) $(TB_SRC) $(RTL_SRC) $(DPI_WRAPPER_OBJ) $(MODEL_OBJ)

run: build
	$(OBJ_DIR)/V$(TOP) $(RUN_ARGS)

wave: build
	$(OBJ_DIR)/V$(TOP) $(RUN_ARGS) +dump +dumpfile=$(DUMPFILE)
	@printf '%s\n' "VCD generated: $(DUMPFILE)"

clean:
	rm -rf $(OBJ_DIR)
