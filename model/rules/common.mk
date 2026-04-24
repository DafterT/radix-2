CC ?= gcc
PYTHON ?= python3
CFLAGS ?= -std=c11 -Wall -Wextra -O3
LDLIBS ?= -lm
EXE_EXT := $(if $(filter Windows_NT,$(OS)),.exe,)

model_backend = $(or $(MODEL_BACKEND_$(1)),c)
model_build_dir = $(BUILD_DIR)/$(1)
model_exe = $(call model_build_dir,$(1))/$(1)$(EXE_EXT)
