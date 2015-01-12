#
# Build environment for miniboot.
#

CHERIROOT?=../..
CHERIROOT_ABS:=$(realpath $(CHERIROOT))
CHERILIBS?=../../../../cherilibs/trunk
CHERILIBS_ABS:=$(realpath $(CHERILIBS))
CHERICONF?=simconfig
TOOLS_DIR=${CHERILIBS_ABS}/tools
TOOLS_DIR_ABS:=$(realpath $(TOOLS_DIR))

MEMCONV=python $(TOOLS_DIR_ABS)/memConv.py
AS=mips64-as
CC=sde-gcc

CFLAGS += -EB -march=mips64 -mabi=64 -G 0 -ggdb -O1 -S

LDSCRIPT=miniboot.ld

.DUMMY=all
all: miniboot.elf mem.bin miniboot.dump

miniboot.o : miniboot.s init.c
	$(CC) -c -o init.s init.c $(CFLAGS)
	$(AS) -EB -march=mips64 -mabi=64 -G0 -ggdb -o miniboot.o miniboot.s init.s
miniboot.elf : miniboot.o $(LDSCRIPT)
	sde-ld -EB -G0 -T$(LDSCRIPT) $< -o $@ -m elf64btsmip
miniboot.mem : miniboot.elf
	sde-objcopy -S -O binary $< $@
miniboot.dump : miniboot.elf
	mips64-objdump -xsSD $< > $@

mem.bin: miniboot.mem
	cp $< $@
	$(MEMCONV) bsim
	$(MEMCONV) verilog

run:
	LD_LIBRARY_PATH=$(CHERILIBS_ABS)/peripherals			\
	    CHERI_KERNEL=kernel						\
	    CHERI_CONFIG=$(CHERICONF)					\
	    ${CHERIROOT_ABS}/sim

trace:
ifndef CHERI_TRACE_LOG
	@echo "Must set CHERI_TRACE_LOG to use trace target"
	@exit 1
endif
ifndef CHERI_CONSOLE_SOCKET
	@echo "Must set CHERI_CONSOLE_SOCKET to use trace target"
	@exit 1
endif
	LD_LIBRARY_PATH=$(CHERILIBS_ABS)/peripherals			\
	    CHERI_KERNEL=kernel						\
	    CHERI_CONSOLE_SOCKET=$(CHERI_CONSOLE_SOCKET)		\
	    CHERI_CONFIG=$(CHERICONF)					\
	    ${CHERIROOT_ABS}/sim		\
	    +regDump +trace +cTrace +instructionBasedCycleCounter > $(CHERI_TRACE_LOG)

gxemul:
	../../../cheritest/trunk/tools/gxemul/CTSRD-CHERI-gxemul-8d92b42/gxemul -V -E oldtestmips -M 3072 kernel.gxemul miniboot.elf

clean:
	rm -f *.o *.elf *.mem *.dump mem.bin mem?.hex initial.hex mem.hex mem64.hex sim.so kernel-sdroot init.s
