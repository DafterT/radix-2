THIS_DIR := $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
ROOT_DIR := $(abspath $(THIS_DIR)/..)
BUILD_DIR ?= $(THIS_DIR)/build
TESTS_DIR := $(THIS_DIR)/tests
RULES_DIR := $(THIS_DIR)/rules

include $(RULES_DIR)/common.mk

TEST_MAKEFILES := $(wildcard $(TESTS_DIR)/*/test.mk)
include $(TEST_MAKEFILES)

include $(RULES_DIR)/iverilog.mk
include $(RULES_DIR)/verilator.mk
include $(RULES_DIR)/targets.mk
