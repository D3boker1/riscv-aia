# SPDX-License-Identifier: Apache-2.0
# Copyright © 2023 Francisco Marques & Zero-Day Labs, Lda. All rights reserved.
#
# Author: F.Marques <fmarques_00@protonmail.com>

# Notifier Makefile

CLEAN =

# defaults
SIM ?= verilator
EXTRA_ARGS += --trace --trace-structs
TOPLEVEL_LANG ?= verilog

AXI_FOLDER = $(PWD)/../../../vendor/
TEST_FOLDER = $(currdir) 
WRAPPER_SRC = $(TEST_FOLDER)./wrap.sv
SRC_FOLDER = $(PWD)/../../../rtl
APLIC_FOLDER = $(SRC_FOLDER)/aplic
APLIC_COMMON_FOLDER = $(APLIC_FOLDER)/common
APLIC_MINIMAL_FOLDER = $(APLIC_FOLDER)/minimal
APLIC_SCALABLE_FOLDER = $(APLIC_FOLDER)/scalable

VERILOG_SOURCES += $(AXI_FOLDER)reg_intf_pkg.sv
VERILOG_SOURCES += $(APLIC_COMMON_FOLDER)/aplic_define_direct.svh
VERILOG_SOURCES += $(APLIC_MINIMAL_FOLDER)/aplic_domain_regctl.sv
VERILOG_SOURCES += $(APLIC_MINIMAL_FOLDER)/aplic_regmap_32_2.sv
VERILOG_SOURCES += $(WRAPPER_SRC)

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = aplic_domain_regctl_wrapper

# MODULE is the basename of the Python test file
MODULE = aplic_domain_regctl_tb

include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf $(PWD)/__pycache__
	rm $(PWD)/results.xml
