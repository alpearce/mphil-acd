VERILOGDEST=../qsys_ip/opencore_16550_uart
VERILOGSRC=$(wildcard *.v)
TCLSRC=$(wildcard *.tcl)

all: $(VERILOGDEST)

$(VERILOGDEST):
	mkdir $(VERILOGDEST)
	cp $(VERILOGSRC) $(VERILOGDEST)
	cp $(TCLSRC) $(VERILOGDEST)

clean:
	rm -f  *~
	rm -rf $(VERILOGDEST)
