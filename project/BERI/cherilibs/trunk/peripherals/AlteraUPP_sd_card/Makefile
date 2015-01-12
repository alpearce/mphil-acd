# this file has three purposes:

# 1. Copy the relevant files into the qsys_ip directory
# 2. If we don't have the files, download the upstream sources and patch them

VERILOGDEST=../qsys_ip/AlteraUPP_sd_card

UPSTREAM_DIR=../AlteraUPP_IP_upstream
UPSTREAM_SD=$(UPSTREAM_DIR)/University_Program/Memory/altera_up_sd_card_avalon_interface
PATCH_FILE=AlteraUPP_sd_card.p
TOPLEVEL=Altera_UP_SD_Card_Avalon_Interface.vhd

all: $(VERILOGDEST)/$(TOPLEVEL)

.PHONY: makepatch

$(VERILOGDEST):
	mkdir -p $(VERILOGDEST)

$(TOPLEVEL):	| $(VERILOGDEST)
	wget ftp://ftp.altera.com/up/pub/Altera_Material/11.0/University_Program_IP_Cores/University_Program.zip
	mkdir -p $(UPSTREAM_DIR)
	unzip -d $(UPSTREAM_DIR) University_Program.zip
	cp $(UPSTREAM_SD)/hdl/* .
	cp $(UPSTREAM_SD)/*.tcl .
	patch < $(PATCH_FILE)

$(VERILOGDEST)/$(TOPLEVEL):	$(TOPLEVEL)
	cp *.vhd $(VERILOGDEST)
	cp *.tcl $(VERILOGDEST)

clean:
	rm -f  *~
	rm -rf $(VERILOGDEST)
	rm -f University_Program.zip
	rm -rf $(UPSTREAM_DIR)

# or alternatively 3. generate patches from the changed versions we have here
# (as part of the release process only)

makepatch:	$(UPSTREAM_DIR)
	diff -ud -x '*.bak' -x 'transcript' -x '*.bsf' -x '*.cmp' -x '*.qip' $(UPSTREAM_SD)/hdl . > $(PATCH_FILE); [ $$? -eq 1 ]
	diff -ud $(UPSTREAM_SD) . >> $(PATCH_FILE); [ $$? -eq 1 ]
