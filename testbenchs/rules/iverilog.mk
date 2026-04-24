iverilog_build_dir = $(BUILD_DIR)/iverilog/$(1)
iverilog_simv = $(call iverilog_build_dir,$(1))/$(call test_top,$(1)).vvp

.PHONY: __build-iverilog __run-iverilog __wave-iverilog

__build-iverilog:
	mkdir -p $(call iverilog_build_dir,$(TEST))
	$(IVERILOG) $(IVFLAGS_COMMON) $(TEST_IVERILOG_FLAGS_$(TEST)) -o $(call iverilog_simv,$(TEST)) $(TEST_SV_SRCS_$(TEST))

__run-iverilog: __build-iverilog
	$(VVP) $(call iverilog_simv,$(TEST)) $(TEST_RUN_ARGS_$(TEST))

__wave-iverilog: __build-iverilog
	mkdir -p $(BUILD_DIR)/waves
	$(VVP) $(call iverilog_simv,$(TEST)) $(TEST_RUN_ARGS_$(TEST)) +dump +dumpfile=$(call wave_file,$(TEST))
	@printf '%s\n' "VCD generated: $(call wave_file,$(TEST))"
