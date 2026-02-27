PYTHON ?= python3
SCRIPT := verify_dpi_complex_fixed_test.py
OUT ?= generated_test_cases.c

.PHONY: all console file clean

all: console

console:
	$(PYTHON) $(SCRIPT)

file:
	$(PYTHON) $(SCRIPT) > $(OUT)
	@echo Written: $(OUT)

clean:
	$(RM) $(OUT)
