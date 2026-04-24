.PHONY: all build run run-all list-models clean check-model __build-c __run-c __build-command __run-command

KNOWN_MODELS := $(MODELS) $(OPTIONAL_MODELS)

all: run-all

check-model:
	@if [ -z "$(MODEL)" ]; then \
		printf '%s\n' "Set MODEL=<name>. Available models: $(KNOWN_MODELS)"; \
		exit 2; \
	fi
	@if [ -z "$(filter $(MODEL),$(KNOWN_MODELS))" ]; then \
		printf '%s\n' "Unknown MODEL='$(MODEL)'. Available models: $(KNOWN_MODELS)"; \
		exit 2; \
	fi

build: check-model
	$(MAKE) --no-print-directory __build-$(call model_backend,$(MODEL)) MODEL=$(MODEL)

run: check-model
	$(MAKE) --no-print-directory __run-$(call model_backend,$(MODEL)) MODEL=$(MODEL)

build-%:
	$(MAKE) --no-print-directory build MODEL=$*

run-%:
	$(MAKE) --no-print-directory run MODEL=$*

run-all: $(addprefix run-,$(MODELS))

list-models:
	@printf '%s\n' $(KNOWN_MODELS)

clean:
	rm -rf $(BUILD_DIR)

__build-c: $(MODEL_PREBUILD_$(MODEL))
	mkdir -p $(call model_build_dir,$(MODEL))
	$(CC) $(CFLAGS) $(MODEL_INC_FLAGS_$(MODEL)) $(MODEL_DEFS_$(MODEL)) $(MODEL_SRCS_$(MODEL)) -o $(call model_exe,$(MODEL)) $(MODEL_LDLIBS_$(MODEL)) $(LDLIBS)

__run-c: __build-c
	$(call model_exe,$(MODEL)) $(MODEL_RUN_ARGS_$(MODEL))

__build-command:
	@:

__run-command:
	$(MODEL_RUN_CMD_$(MODEL))
