#-
# Copyright (c) 2013 Colin Rothwell
# All rights reserved.
#
# This software was developed by Colin Rothwell as part of his final year
# undergraduate project.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
BSC=bsc
SHARED_SRCS=../megafunctions/*.bsv
# Include CoProcessor, Cheri and Megafunctions
BSV_PATH=+:../..:../../bsim:..:../megafunctions 
BSCFLAGS=-keep-fires -cross-info -aggressive-conditions -p $(BSV_PATH)
BSCFLAGS+=-bdir bsim -simdir bsim -u +RTS -K4GB -RTS
SIMFLAGS=-sim -D BLUESIM
VERILOGFLAGS=-vdir verilog -verilog

ifdef MEGAFUNCTIONS
	BSCFLAGS+=-D MEGAFUNCTIONS
endif

BUILDSIM = $(BSC) $(BSCFLAGS) $(SIMFLAGS) $(1) &&\
		   $(BSC) $(BSCFLAGS) $(SIMFLAGS) -l mpfr -l gmp -e $(2) -o simulation/$(2)

BUILDVERILOG=$(BSC) $(BSCFLAGS) $(VERILOGFLAGS) -o verilog/$@ $<

#TODO: Add a "make all" rule.

bsim/%.bo: %.bsv
	$(BSC) $(BSCFLAGS) $<

simulation/mkInstantiateCoPro:
	$(call BUILDSIM,InstantiateCoPro.bsv,mkInstantiateCoPro)

simulation/mkCompositeOpTests: 
	$(call BUILDSIM,CompositeOpTests.bsv,mkCompositeOpTests)

simulation/mkDiadicMegafunctionSimulationTests:
	$(call BUILDSIM,DiadicMegafunctionSimulationTests.bsv,mkDiadicMegafunctionSimulationTests)

simulation/mkFloatingPointConversionTest:
	$(call BUILDSIM,FloatingPointConversionTest.bsv,mkFloatingPointConversionTest)

simulation/mkMegafunctionServerTests: MegafunctionServerTests.bsv
	$(call BUILDSIM,MegafunctionServerTests.bsv,mkMegafunctionServerTests)

verilog/mkMegafunctionServerTests.v: MegafunctionServerTests.bsv
	$(call BUILDVERILOG,mkMegafunctionServerTests)

simulation/mkMonadicMegafunctionTests:
	$(call BUILDSIM,MonadicMegafunctionTests.bsv,mkMonadicMegafunctionTests)

simulation/mkDiadicMegafunctionWrapperTestBench:
	$(call BUILDSIM,TestDiadicMegafunctionWrapper.bsv,mkDiadicMegafunctionWrapperTestBench)

simulation/mkConversionTests: ConversionTests.bsv
	$(call BUILDSIM,ConversionTests.bsv,mkConversionTests)

simulation/mkDivTests: DivTests.bsv
	$(call BUILDSIM,DivTests.bsv,mkDivTests)

.PHONY: clean
clean:
	rm -rf bsim/* simulation/*
