verilator_build_dir = $(BUILD_DIR)/verilator/$(1)
verilator_exe = $(call verilator_build_dir,$(1))/V$(call test_top,$(1))
verilator_wrapper_obj = $(call verilator_build_dir,$(1))/dpi_wrapper.o
verilator_model_objs = $(patsubst %.c,$(call verilator_build_dir,$(1))/%.o,$(notdir $(TEST_MODEL_SRCS_$(1))))

.PHONY: __build-verilator __run-verilator __wave-verilator

__build-verilator:
	mkdir -p $(call verilator_build_dir,$(TEST))
	@for src in $(TEST_MODEL_SRCS_$(TEST)); do \
		base=$$(basename "$$src" .c); \
		$(CC) $(CFLAGS) $(TEST_MODEL_INC_FLAGS_$(TEST)) -c "$$src" -o "$(call verilator_build_dir,$(TEST))/$$base.o"; \
	done
	$(CC) $(CFLAGS) -I$(dir $(TEST_DPI_WRAPPER_$(TEST))) $(TEST_MODEL_INC_FLAGS_$(TEST)) -I$(VERILATOR_DPI_INC) -c $(TEST_DPI_WRAPPER_$(TEST)) -o $(call verilator_wrapper_obj,$(TEST))
	$(VERILATOR) $(VERILATOR_FLAGS_COMMON) --top-module $(call test_top,$(TEST)) --Mdir $(call verilator_build_dir,$(TEST)) -LDFLAGS "$(LDLIBS)" $(TEST_VERILATOR_FLAGS_$(TEST)) $(TEST_SV_SRCS_$(TEST)) $(call verilator_wrapper_obj,$(TEST)) $(call verilator_model_objs,$(TEST))

__run-verilator: __build-verilator
	$(call verilator_exe,$(TEST)) $(TEST_RUN_ARGS_$(TEST))

__wave-verilator: __build-verilator
	mkdir -p $(BUILD_DIR)/waves
	$(call verilator_exe,$(TEST)) $(TEST_RUN_ARGS_$(TEST)) +dump +dumpfile=$(call wave_file,$(TEST))
	@printf '%s\n' "VCD generated: $(call wave_file,$(TEST))"
