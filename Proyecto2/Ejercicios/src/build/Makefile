# =========================================
# Tang Nano 9K - Proyecto divisor de reloj
# =========================================

BOARD  = tangnano9k
FAMILY = GW1N-9C
DEVICE = GW1NR-LV9QN88PC6/I5

PROJECT = clk_div

TOP_DESIGN = clk_div

SOURCES = ../design/clk_div.sv

CONSTRAINTS = ../constr/pines.cst

all: synth pnr bitstream load

# =========================================
# Sintesis
# =========================================

synth:
	yosys -p "read_verilog -sv $(SOURCES); synth_gowin -top $(TOP_DESIGN) -json $(PROJECT).json"

# =========================================
# Place and Route
# =========================================

pnr:
	nextpnr-gowin \
	--json $(PROJECT).json \
	--write $(PROJECT)_pnr.json \
	--device $(DEVICE) \
	--family $(FAMILY) \
	--cst $(CONSTRAINTS) \
	--freq 27

# =========================================
# Bitstream
# =========================================

bitstream:
	gowin_pack -d $(FAMILY) \
	-o $(PROJECT).fs \
	$(PROJECT)_pnr.json

# =========================================
# Cargar FPGA
# =========================================

load:
	openFPGALoader -b $(BOARD) $(PROJECT).fs

# =========================================
# Limpiar
# =========================================

clean:
	rm -f *.json
	rm -f *.fs
	rm -f *_pnr.json