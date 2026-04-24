VERILATOR ?= verilator
CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11
VERILATOR_DPI_INC ?= /usr/share/verilator/include/vltstd
LDLIBS ?= -lm

THIS_DIR := $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
TB_DIR := $(abspath $(THIS_DIR)/..)
ROOT_DIR := $(abspath $(TB_DIR)/..)
BUILD_DIR := $(TB_DIR)/build
OBJ_ROOT := $(THIS_DIR)/obj_dir
OBJ_DIR := $(OBJ_ROOT)/$(TOP)
SV_PKG := $(ROOT_DIR)/rtl/complex_fixed_pkg.sv

TOP ?= dsp48e2_slice_model_dpi_tb

PREADD_SUB ?= 0
POSTADD_EN ?= 1
POSTADD_SUB ?= 0
RESET_CYCLES ?= 4
FRAMES ?= 32
SEED ?= 1
BACKOFF_DB ?= 12.0

INFILE ?=
DUMPFILE ?= $(BUILD_DIR)/$(TOP).vcd

VERILATOR_FLAGS := --binary --sv --timing --trace -Wall -Wno-fatal
VERILATOR_FLAGS += --top-module $(TOP)
VERILATOR_FLAGS += --Mdir $(OBJ_DIR)
VERILATOR_FLAGS += -LDFLAGS "$(LDLIBS)"

ifeq ($(TOP),dsp48e2_slice_model_dpi_tb)
TB_SRC := $(TB_DIR)/dsp48e2_slice_model_dpi_tb.sv
SV_SRC := $(TB_SRC) $(ROOT_DIR)/rtl/dsp48e2_slice_model.sv
MODEL_DIR := $(ROOT_DIR)/model/dsp48e2_like
MODEL_SRCS := $(MODEL_DIR)/dsp48e2_like_model.c
DPI_WRAPPER_SRC := $(THIS_DIR)/dsp48e2_slice_model_dpi.c
MODEL_OBJS := $(OBJ_DIR)/dsp48e2_like_model.o
DPI_WRAPPER_OBJ := $(OBJ_DIR)/dsp48e2_slice_model_dpi.o
MODEL_INC_FLAGS := -I$(MODEL_DIR)
VERILATOR_FLAGS += -GPREADD_SUB=$(PREADD_SUB)
VERILATOR_FLAGS += -GPOSTADD_EN=$(POSTADD_EN)
VERILATOR_FLAGS += -GPOSTADD_SUB=$(POSTADD_SUB)
RUN_ARGS := +infile=$(if $(INFILE),$(INFILE),$(TB_DIR)/input/input_vectors.txt)
else ifeq ($(TOP),complex_mul_3dsp_dpi_tb)
TB_SRC := $(TB_DIR)/complex_mul_3dsp_dpi_tb.sv
SV_SRC := $(SV_PKG) $(TB_SRC) $(ROOT_DIR)/rtl/dsp48e2_slice_model.sv $(ROOT_DIR)/rtl/complex_mul_3dsp.sv
MODEL_DIR := $(ROOT_DIR)/model/complex_mul_3dsp
MODEL_SRCS := $(MODEL_DIR)/complex_mul_3dsp_model.c
DPI_WRAPPER_SRC := $(THIS_DIR)/complex_mul_3dsp_dpi.c
MODEL_OBJS := $(OBJ_DIR)/complex_mul_3dsp_model.o
DPI_WRAPPER_OBJ := $(OBJ_DIR)/complex_mul_3dsp_dpi.o
MODEL_INC_FLAGS := -I$(MODEL_DIR)
VERILATOR_FLAGS += -GRESET_CYCLES=$(RESET_CYCLES)
RUN_ARGS := +infile=$(if $(INFILE),$(INFILE),$(TB_DIR)/input/input_complex_vectors.txt)
else ifeq ($(TOP),fft64_core_dpi_tb)
TB_SRC := $(TB_DIR)/fft64_core_dpi_tb.sv
SV_SRC := $(SV_PKG) $(TB_SRC) \
	$(ROOT_DIR)/rtl/dsp48e2_slice_model.sv \
	$(ROOT_DIR)/rtl/complex_requantize_q22_23_to_q16_0.sv \
	$(ROOT_DIR)/rtl/complex_mul_3dsp.sv \
	$(ROOT_DIR)/rtl/convergent_rounding.sv \
	$(ROOT_DIR)/rtl/simple_dual_port_ram.sv \
	$(ROOT_DIR)/rtl/twiddle_rom.sv \
	$(ROOT_DIR)/rtl/radix2_butterfly.sv \
	$(ROOT_DIR)/rtl/fft64_controller.sv \
	$(ROOT_DIR)/rtl/fft64_core.sv \
	$(ROOT_DIR)/rtl/delay_line_with_valid.sv \
	$(ROOT_DIR)/rtl/symmetric_saturate.sv
MODEL_FIXED_DIR := $(ROOT_DIR)/model/fft64/fixed_sqrt2
MODEL_TOOLS_DIR := $(ROOT_DIR)/model/fft64/tools
MODEL_SRCS := $(MODEL_FIXED_DIR)/model_fixed.c $(MODEL_FIXED_DIR)/butterfly_fixed.c $(MODEL_TOOLS_DIR)/fft64_white_noise.c
MODEL_OBJS := $(OBJ_DIR)/model_fixed.o $(OBJ_DIR)/butterfly_fixed.o $(OBJ_DIR)/fft64_white_noise.o
DPI_WRAPPER_SRC := $(THIS_DIR)/fft64_core_dpi.c
DPI_WRAPPER_OBJ := $(OBJ_DIR)/fft64_core_dpi.o
MODEL_INC_FLAGS := -I$(MODEL_FIXED_DIR) -I$(MODEL_TOOLS_DIR)
RUN_ARGS := +frames=$(FRAMES) +seed=$(SEED) +backoff_db=$(BACKOFF_DB)
else
$(error Unsupported TOP '$(TOP)')
endif

DPI_INC_FLAGS := -I$(THIS_DIR) $(MODEL_INC_FLAGS) -I$(VERILATOR_DPI_INC)

.PHONY: all build run wave clean

all: run

build:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(OBJ_DIR)
	@for src in $(MODEL_SRCS); do \
		base=$$(basename "$$src" .c); \
		$(CC) $(CFLAGS) $(MODEL_INC_FLAGS) -c "$$src" -o "$(OBJ_DIR)/$$base.o"; \
	done
	$(CC) $(CFLAGS) $(DPI_INC_FLAGS) -c $(DPI_WRAPPER_SRC) -o $(DPI_WRAPPER_OBJ)
	$(VERILATOR) $(VERILATOR_FLAGS) $(SV_SRC) $(DPI_WRAPPER_OBJ) $(MODEL_OBJS)

run: build
	$(OBJ_DIR)/V$(TOP) $(RUN_ARGS)

wave: build
	$(OBJ_DIR)/V$(TOP) $(RUN_ARGS) +dump +dumpfile=$(DUMPFILE)
	@printf '%s\n' "VCD generated: $(DUMPFILE)"

clean:
	rm -rf $(OBJ_ROOT)
