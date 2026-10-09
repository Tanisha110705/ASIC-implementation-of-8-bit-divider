# Open-source RTL simulation of eight_bit_divider with Icarus Verilog.
# The Cadence flows (Xcelium GLS, Conformal LEC) are documented in
# docs/reproduction.md; they need licensed tools and are not run from here.
#
#   make sim         directed testbench (original 6 cases, prints results)
#   make exhaustive  self-checking testbench (all 65,536 operand pairs)
#   make lint        Yosys parse/synthesis check with cell statistics
#   make clean

IVERILOG ?= iverilog
VVP      ?= vvp
YOSYS    ?= yosys
BUILD    ?= build

RTL := ../rtl/divider.v

.PHONY: all sim exhaustive lint clean
all: sim exhaustive

$(BUILD):
	mkdir -p $(BUILD)

sim: | $(BUILD)
	$(IVERILOG) -g2005 -Wall -o $(BUILD)/directed.vvp $(RTL) testbench/tb_divider_8bit.v
	$(VVP) -n $(BUILD)/directed.vvp

exhaustive: | $(BUILD)
	$(IVERILOG) -g2005 -Wall -o $(BUILD)/exhaustive.vvp $(RTL) testbench/tb_divider_exhaustive.v
	$(VVP) -n $(BUILD)/exhaustive.vvp | tee $(BUILD)/exhaustive.log
	@grep -q "TEST PASSED" $(BUILD)/exhaustive.log

lint:
	$(YOSYS) -p "read_verilog $(RTL); synth -top eight_bit_divider; check -assert; stat"

clean:
	rm -rf $(BUILD)
