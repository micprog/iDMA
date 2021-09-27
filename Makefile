GIT ?= git
BENDER ?= bender
VSIM ?= vsim
PYTHON ?= python3

all: sim_all

clean: sim_clean

# Ensure half-built targets are purged
.DELETE_ON_ERROR:

# --------------
# RTL SIMULATION
# --------------

VLOG_ARGS += -suppress vlog-2583 -suppress vlog-13314 -suppress vlog-13233 -timescale \"1 ns / 1 ps\"
XVLOG_ARGS += -64bit -compile -vtimescale 1ns/1ns -quiet

define generate_vsim
	echo 'set ROOT [file normalize [file dirname [info script]]/$3]' > $1
	bender script $(VSIM) --vlog-arg="$(VLOG_ARGS)" $2 | grep -v "set ROOT" >> $1
	echo >> $1
endef

sim_all: scripts/compile.tcl

sim_clean:
	rm -rf scripts/compile.tcl
	rm -rf work

scripts/compile.tcl: Bender.yml
	$(call generate_vsim, $@, -t rtl -t test,..)

# --------------
# TRACER
# --------------

trace:
	dma_trace_00000.txt

dma_trace_%.txt: scripts/dma_trace.py scripts/dma_backend.py
	$(PYTHON) $< dma_trace_$*.log > $@

REG_PATH = $(shell $(BENDER) path register_interface)
REG_TOOL = $(REG_PATH)/vendor/lowrisc_opentitan/util/regtool.py
PULPOPEN_FE_DIR = src/frontends/pulpopen
HJSON = $(PULPOPEN_FE_DIR)/cluster_dma_frontend.hjson

pulpopen_regs:
	$(PYTHON) $(REG_TOOL) $(HJSON) -t $(PULPOPEN_FE_DIR) -r
	$(PYTHON) $(REG_TOOL) $(HJSON) -d > $(PULPOPEN_FE_DIR)/doc.html
	$(PYTHON) $(REG_TOOL) $(HJSON) -D > $(PULPOPEN_FE_DIR)/pulp_idma.h
