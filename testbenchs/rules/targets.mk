.PHONY: all build run wave run-all wave-all clean list-tests check-test

all: run-all

check-test:
	@if [ -z "$(TEST)" ]; then \
		printf '%s\n' "Set TEST=<name>. Available tests: $(TESTS)"; \
		exit 2; \
	fi
	@if [ -z "$(filter $(TEST),$(TESTS))" ]; then \
		printf '%s\n' "Unknown TEST='$(TEST)'. Available tests: $(TESTS)"; \
		exit 2; \
	fi

build: check-test
	$(MAKE) --no-print-directory __build-$(call test_backend,$(TEST)) TEST=$(TEST)

run: check-test
	$(MAKE) --no-print-directory __run-$(call test_backend,$(TEST)) TEST=$(TEST)

wave: check-test
	$(MAKE) --no-print-directory __wave-$(call test_backend,$(TEST)) TEST=$(TEST)

build-%:
	$(MAKE) --no-print-directory build TEST=$*

run-%:
	$(MAKE) --no-print-directory run TEST=$*

wave-%:
	$(MAKE) --no-print-directory wave TEST=$*

run-all: $(addprefix run-,$(TESTS))

wave-all: $(addprefix wave-,$(TESTS))

list-tests:
	@printf '%s\n' $(TESTS)

clean:
	rm -rf $(BUILD_DIR)
