#!/usr/bin/make -f

BSC=bsc
# SWM: use aggressive conditions and add path to fine Avalon2ClientServer, etc.
LIBS=../../
BSCFLAGS=-keep-fires -cross-info -aggressive-conditions -p +:$(LIBS)
SUFFIXES=
VERILOGDEST=../qsys_ip/MTL_LCD
GENVERILOG=$(VERILOGDEST)/mkAvalonStream2MTL_LCD24bit.v $(VERILOGDEST)/mkMTL_Framebuffer.v $(VERILOGDEST)/mkMTL_Framebuffer_Flash.v
HW_TCL=$(VERILOGDEST)/AvalonStream2MTL_LCD24bit_hw.tcl $(VERILOGDEST)/mkMTL_Framebuffer_hw.tcl $(VERILOGDEST)/mkMTL_Framebuffer_Flash_hw.tcl
EXTRA=$(VERILOGDEST)/vgafontrom.mif $(VERILOGDEST)/i2c_touch_config.v $(VERILOGDEST)/VerilogAlteraROM.v

all: $(VERILOGDEST) $(GENVERILOG) $(HW_TCL) $(EXTRA)

$(VERILOGDEST):
	mkdir $(VERILOGDEST)

$(VERILOGDEST)/mkAvalonStream2MTL_LCD24bit.v: MTL_LCD_Driver.bsv
	$(BSC) $(BSCFLAGS) -vdir $(VERILOGDEST) -u -verilog -g mkAvalonStream2MTL_LCD24bit MTL_LCD_Driver.bsv

$(VERILOGDEST)/mkMTL_Framebuffer.v: MTL_Framebuffer.bsv
	$(BSC) $(BSCFLAGS) -vdir $(VERILOGDEST) -u -verilog -g mkMTL_Framebuffer MTL_Framebuffer.bsv

$(VERILOGDEST)/mkMTL_Framebuffer_Flash.v: MTL_Framebuffer_Flash.bsv
	$(BSC) $(BSCFLAGS) -vdir $(VERILOGDEST) -u -verilog -g mkMTL_Framebuffer_Flash MTL_Framebuffer_Flash.bsv

$(VERILOGDEST)/AvalonStream2MTL_LCD24bit_hw.tcl: AvalonStream2MTL_LCD24bit_hw.tcl
	cp AvalonStream2MTL_LCD24bit_hw.tcl $(VERILOGDEST)

$(VERILOGDEST)/mkMTL_Framebuffer_hw.tcl: mkMTL_Framebuffer_hw.tcl
	cp mkMTL_Framebuffer_hw.tcl $(VERILOGDEST)

$(VERILOGDEST)/mkMTL_Framebuffer_Flash_hw.tcl: mkMTL_Framebuffer_Flash_hw.tcl
	cp mkMTL_Framebuffer_Flash_hw.tcl $(VERILOGDEST)

$(VERILOGDEST)/vgafontrom.mif: vgafontrom.mif
	cp vgafontrom.mif $(VERILOGDEST)

$(VERILOGDEST)/i2c_touch_config.v: i2c_touch_config.v
	cp i2c_touch_config.v $(VERILOGDEST)

$(VERILOGDEST)/VerilogAlteraROM.v: VerilogAlteraROM.v
	cp VerilogAlteraROM.v $(VERILOGDEST)

# SWM: remove *.c from "clean" since this will delete mtl_test_small.c that we want to keep
.PHONY: clean
clean:
	rm -f  *.bi *.bo *.ba *.info *.sched *.h *.o *.so $(GENVERILOG) $(HW_TCL) $(EXTRA) >/dev/null
	rm -rf $(VERILOGDEST)
