#!/usr/bin/make -f
#

BSC=bsc
# SWM: use aggressive conditions and add path to fine Avalon2ClientServer, etc.
LIBS=../../
BSCFLAGS=-keep-fires -cross-info -aggressive-conditions -p +:$(LIBS)
SUFFIXES=
VERILOGDEST=../qsys_ip/MTL_LCD_HDMI

all: $(VERILOGDEST) $(VERILOGDEST)/mkAvalonStream2LCDandHDMI.v

$(VERILOGDEST):
	mkdir $(VERILOGDEST)

# synthesise Bluespec components and copy over Qsys _hw.tcl component descriptions
$(VERILOGDEST)/mkAvalonStream2LCDandHDMI.v: MTL_LCD_HDMI_Driver.bsv Makefile
	$(BSC) $(BSCFLAGS) -vdir $(VERILOGDEST) -u -verilog -g mkAvalonStream2LCDandHDMI MTL_LCD_HDMI_Driver.bsv
	cp *_hw.tcl $(VERILOGDEST)
	rm -f *.bo

.PHONY: clean
clean:
	rm -f  *.bi *.bo *.ba *.info *.sched *.h *.o *.so  mk*.v $(VERILOGDEST)/mk*.v $(VERILOGDEST)/*_hw.tcl *~ >/dev/null
	rm -rf $(VERILOGDEST)
