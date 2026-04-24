TESTS += dsp48e2_slice_model

PREADD_SUB ?= 0
POSTADD_EN ?= 1
POSTADD_SUB ?= 0

TEST_BACKEND_dsp48e2_slice_model := verilator
TEST_TOP_dsp48e2_slice_model := dsp48e2_slice_model_dpi_tb
TEST_DIR_dsp48e2_slice_model := $(TESTS_DIR)/dsp48e2_slice_model
TEST_SV_SRCS_dsp48e2_slice_model := \
	$(TEST_DIR_dsp48e2_slice_model)/tb.sv \
	$(ROOT_DIR)/rtl/dsp48e2_slice_model.sv
TEST_DPI_WRAPPER_dsp48e2_slice_model := $(TEST_DIR_dsp48e2_slice_model)/dpi_wrapper.c
TEST_MODEL_SRCS_dsp48e2_slice_model := $(ROOT_DIR)/model/dsp48e2_slice_model/dsp48e2_slice_model.c
TEST_MODEL_INC_FLAGS_dsp48e2_slice_model := -I$(ROOT_DIR)/model/dsp48e2_slice_model
TEST_VERILATOR_FLAGS_dsp48e2_slice_model := \
	-GPREADD_SUB=$(PREADD_SUB) \
	-GPOSTADD_EN=$(POSTADD_EN) \
	-GPOSTADD_SUB=$(POSTADD_SUB)
TEST_RUN_ARGS_dsp48e2_slice_model := +infile=$(TEST_DIR_dsp48e2_slice_model)/input.txt
