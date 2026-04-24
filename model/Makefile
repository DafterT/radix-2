THIS_DIR := $(patsubst %/,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
ROOT_DIR := $(abspath $(THIS_DIR)/..)
BUILD_DIR ?= $(THIS_DIR)/build
RULES_DIR := $(THIS_DIR)/rules

include $(RULES_DIR)/common.mk

MODEL_MAKEFILES := $(wildcard $(THIS_DIR)/*/model.mk)
include $(MODEL_MAKEFILES)

include $(RULES_DIR)/targets.mk
