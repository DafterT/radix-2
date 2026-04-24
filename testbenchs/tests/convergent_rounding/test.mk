TESTS += convergent_rounding

TEST_BACKEND_convergent_rounding := iverilog
TEST_TOP_convergent_rounding := convergent_rounding_tb
TEST_DIR_convergent_rounding := $(TESTS_DIR)/convergent_rounding
TEST_SV_SRCS_convergent_rounding := \
	$(TEST_DIR_convergent_rounding)/tb.sv \
	$(ROOT_DIR)/rtl/convergent_rounding.sv
