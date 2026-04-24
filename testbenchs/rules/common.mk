IVERILOG ?= iverilog
VVP ?= vvp
VERILATOR ?= verilator
CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11
VERILATOR_DPI_INC ?= /usr/share/verilator/include/vltstd
LDLIBS ?= -lm

SV_PKG := $(ROOT_DIR)/rtl/complex_fixed_pkg.sv
IVFLAGS_COMMON := -g2012 -Wall
VERILATOR_FLAGS_COMMON := --binary --sv --timing --trace -Wall -Wno-fatal

test_top = $(TEST_TOP_$(1))
test_backend = $(TEST_BACKEND_$(1))
wave_file = $(BUILD_DIR)/waves/$(1).vcd
