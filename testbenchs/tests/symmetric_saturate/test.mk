TESTS += symmetric_saturate

TEST_BACKEND_symmetric_saturate := iverilog
TEST_TOP_symmetric_saturate := symmetric_saturate_tb
TEST_DIR_symmetric_saturate := $(TESTS_DIR)/symmetric_saturate
TEST_SV_SRCS_symmetric_saturate := \
	$(TEST_DIR_symmetric_saturate)/tb.sv \
	$(ROOT_DIR)/rtl/symmetric_saturate.sv
