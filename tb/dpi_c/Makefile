VERILATOR ?= verilator
CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11
VERILATOR_DPI_INC ?= /usr/share/verilator/include/vltstd

THIS_DIR := $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
TB_DIR := $(abspath $(THIS_DIR)/..)
ROOT_DIR := $(abspath $(TB_DIR)/..)
BUILD_DIR := $(TB_DIR)/build
OBJ_ROOT := $(THIS_DIR)/obj_dir
OBJ_DIR := $(OBJ_ROOT)/$(TOP)
SV_PKG := $(ROOT_DIR)/rtl/radix2_types_pkg.sv

TOP ?= DSP48E2_like_file_tb

PREADD_SUB ?= 0
POSTADD_EN ?= 1
POSTADD_SUB ?= 0
RESET_CYCLES ?= 4

INFILE ?=
DUMPFILE ?= $(BUILD_DIR)/$(TOP).vcd

VERILATOR_FLAGS := --binary --sv --timing --trace -Wall -Wno-fatal
VERILATOR_FLAGS += --top-module $(TOP)
VERILATOR_FLAGS += --Mdir $(OBJ_DIR)

ifeq ($(TOP),DSP48E2_like_file_tb)
TB_SRC := $(TB_DIR)/DSP48E2_like_file_tb.sv
SV_SRC := $(TB_SRC) $(ROOT_DIR)/rtl/DSP48E2_like.sv
MODEL_DIR := $(ROOT_DIR)/model/dsp48e2_like
MODEL_SRC := $(MODEL_DIR)/dsp48e2_like_model.c
DPI_WRAPPER_SRC := $(THIS_DIR)/dsp48e2_like_dpi.c
MODEL_OBJ := $(OBJ_DIR)/dsp48e2_like_model.o
DPI_WRAPPER_OBJ := $(OBJ_DIR)/dsp48e2_like_dpi.o
VERILATOR_FLAGS += -GPREADD_SUB=$(PREADD_SUB)
VERILATOR_FLAGS += -GPOSTADD_EN=$(POSTADD_EN)
VERILATOR_FLAGS += -GPOSTADD_SUB=$(POSTADD_SUB)
RUN_ARGS := +infile=$(if $(INFILE),$(INFILE),$(TB_DIR)/input/input_vectors.txt)
else ifeq ($(TOP),complex_mul_3dsp_file_tb)
TB_SRC := $(TB_DIR)/complex_mul_3dsp_file_tb.sv
SV_SRC := $(SV_PKG) $(TB_SRC) $(ROOT_DIR)/rtl/DSP48E2_like.sv $(ROOT_DIR)/rtl/complex_mul_3dsp.sv
MODEL_DIR := $(ROOT_DIR)/model/complex_mul_3dsp
MODEL_SRC := $(MODEL_DIR)/complex_mul_3dsp_model.c
DPI_WRAPPER_SRC := $(THIS_DIR)/complex_mul_3dsp_dpi.c
MODEL_OBJ := $(OBJ_DIR)/complex_mul_3dsp_model.o
DPI_WRAPPER_OBJ := $(OBJ_DIR)/complex_mul_3dsp_dpi.o
VERILATOR_FLAGS += -GRESET_CYCLES=$(RESET_CYCLES)
RUN_ARGS := +infile=$(if $(INFILE),$(INFILE),$(TB_DIR)/input/input_complex_vectors.txt)
else
$(error Unsupported TOP '$(TOP)')
endif

.PHONY: all build run wave clean

all: run

build:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(OBJ_DIR)
	$(CC) $(CFLAGS) -I$(MODEL_DIR) -c $(MODEL_SRC) -o $(MODEL_OBJ)
	$(CC) $(CFLAGS) -I$(THIS_DIR) -I$(MODEL_DIR) -I$(VERILATOR_DPI_INC) -c $(DPI_WRAPPER_SRC) -o $(DPI_WRAPPER_OBJ)
	$(VERILATOR) $(VERILATOR_FLAGS) $(SV_SRC) $(DPI_WRAPPER_OBJ) $(MODEL_OBJ)

run: build
	$(OBJ_DIR)/V$(TOP) $(RUN_ARGS)

wave: build
	$(OBJ_DIR)/V$(TOP) $(RUN_ARGS) +dump +dumpfile=$(DUMPFILE)
	@printf '%s\n' "VCD generated: $(DUMPFILE)"

clean:
	rm -rf $(OBJ_ROOT)
