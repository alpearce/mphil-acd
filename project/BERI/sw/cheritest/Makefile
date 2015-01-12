CHERILIBS_DIR   = ../../cherilibs/trunk
TOOLS_DIR       = $(CHERILIBS_DIR)/tools
INCLUDE_DIR     = $(CHERILIBS_DIR)/include
BAREMETAL_DIR	= ../baremetal-lib
MINILIB_DIR	= ../minilib-c

CC = sde-gcc
AS = mips64-as
LD = sde-ld
OBJCOPY = sde-objcopy
OBJDUMP = mips64-objdump

ENDIANNESS = -EB
ifndef OPT
  OPT = -O1
endif
CFLAGS += $(ENDIANNESS) -march=mips64 -mabi=64 -G 0 -ggdb $(OPT) -I$(INCLUDE_DIR) -isystem $(MINILIB_DIR)/include -S
ASFLAGS = $(ENDIANNESS) -march=mips64 -mabi=64 -G 0 -ggdb $(OPT)
#c_objects := test.s#$(patsubst %.c,%.o,$(wildcard *.c))

c_objects := test.o $(BAREMETAL_DIR)/cheri-io.o $(BAREMETAL_DIR)/cheri-exp.o
as_objects := test.o $(BAREMETAL_DIR)/cheri-io.o $(BAREMETAL_DIR)/init.o $(BAREMETAL_DIR)/cheri-exp.o $(BAREMETAL_DIR)/lib.o

LDFLAGS = $(ENDIANNESS) -G 0 -L$(BAREMETAL_DIR) -T../cheritest/prog_link.ld -m elf64btsmip

HEX_FILES =			\
	mem64.hex

TARGETS=			\
	binary.dump	\
	elf.dump

MEMCONV=python $(TOOLS_DIR)/memConv.py

../../mem64.hex: $(c_objects) $(as_objects)
	$(LD) $(LDFLAGS) $(as_objects) -o mem.elf
	$(OBJCOPY) -S -O binary mem.elf mem.bin
	$(OBJDUMP) -xsd mem.elf > bsim-elf.dump
	$(MEMCONV)
	cp mem64.hex ../../
	

print-versions:
	$(LD) --version | head -n1
	$(OBJCOPY) --version | head -n1
	$(CC) --version | head -n1
	$(AS) --version | head -n1
	python -V | head -n1

test.o: test.c
	$(CC) -Wall -Wno-return-type -c -o test.s test.c $(CFLAGS)
	$(AS) -o test.o test.s $(ASFLAGS)
lib.o: lib.s
	$(AS) -o $(BAREMETAL_DIR)/lib.o $(BAREMETAL_DIR)/lib.s $(ASFLAGS)
test.c: $(INCLUDE_DIR)/parameters.h

.SUFFIXES:
#.SUFFIXES: .o .c .s

%.s: %.c
	echo $^
	$(CC) $(CFLAGS) -o $@ $^
%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $^

clean:
	rm -f *.elf
	rm -f *.bin
	rm -f *.o $(as_objects)
	rm -f test.s
	rm -f $(HEX_FILES)
	rm -f $(BSIM_TARGETS)
	rm -f $(VERILOG_TARGETS)
