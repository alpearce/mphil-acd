CHERILIBS_DIR   = ../../../../cherilibs/trunk
TOOLS_DIR       = $(CHERILIBS_DIR)/tools
INCLUDE_DIR     = $(CHERILIBS_DIR)/include
SIM_DIR		= ../../../
BAREMETAL_DIR	= ../baremetal-lib/

CLIB_DIR		= ../minilib-c
CLIB_INCLUDE_DIR	= $(CLIB_DIR)/include
CLIB_LIB_DIR		= $(CLIB_DIR)/lib/cheri/GCC

CC = sde-gcc
AS = mips64-as
LD = sde-ld
OBJCOPY = sde-objcopy
OBJDUMP = mips64-objdump

ENDIANNESS = -EB
CFLAGS += $(ENDIANNESS) -march=mips64 -mabi=64 -G 0 -O2 \
	-isystem $(CLIB_INCLUDE_DIR) -nostdinc -I$(INCLUDE_DIR) -fno-builtin
ASFLAGS = $(ENDIANNESS) -march=mips64 -mabi=64 -G 0 


c_objects := hello.o $(BAREMETAL_DIR)/cheri-io.o $(BAREMETAL_DIR)/cheri-exp.o $(BAREMETAL_DIR)/init.o $(BAREMETAL_DIR)/lib.o

CLIB = $(CLIB_DIR)/libmini.a
LIBS = -lmini

LDFLAGS = $(ENDIANNESS) -G 0 -L$(BAREMETAL_DIR) -Tprog_link.ld -m elf64btsmip -L $(CLIB_LIB_DIR)

HEX_FILES =			\
	mem0.hex		\
	mem1.hex		\
	mem2.hex		\
	mem3.hex		\
	mem4.hex		\
	mem5.hex		\
	mem6.hex		\
	mem7.hex		\
	initial.hex

BSIM_TARGETS=			\
	bsim-binary.dump	\
	bsim-elf.dump

VERILOG_TARGETS=		\
	verilog-binary.dump	\
	verilog-elf.dump

MEMCONV=python $(TOOLS_DIR)/memConv.py



default:
	@echo "usage:"
	@echo -e "\tmake bsim"
	@echo -e "\tmake verilog"
	@exit 0;

test.c: $(INCLUDE_DIR)/parameters.h

.SUFFIXES:
.SUFFIXES:	.o .s

%.s:	%.c
	$(CC) $(CFLAGS)  -S $< -o $@

%.o:	%.s
	$(AS) $(ASFLAGS) $< -o $@


bsim: $(BSIM_TARGETS)
$(BSIM_TARGETS) CFLAGS += -DBSIM
$(BSIM_TARGETS): $(c_objects) $(as_objects) $(CLIB)
	$(LD) $(LDFLAGS) $(c_objects) $(as_objects) $(LIBS) -o mem.elf
	$(OBJCOPY) -S -O binary mem.elf mem.bin
	$(OBJDUMP) -xsd mem.elf > bsim-elf.dump
	$(MEMCONV) bsim
	cp *.hex $(SIM_DIR)

verilog: $(VERILOG_TARGETS)
$(VERILOG_TARGETS): $(c_objects) $(as_objects) $(CLIB)
	$(LD) $(LDFLAGS) $(c_objects) $(as_objects) $(LIBS) -o mem.elf
	$(OBJCOPY) -S -O binary mem.elf mem.bin
	$(OBJDUMP) -xsSd mem.elf > verilog-elf.dump
	$(MEMCONV) verilog
	cp *.hex ../

$(CLIB):
	$(MAKE) -C $(CLIB_DIR)

print-versions:
	$(LD) --version | head -n1
	$(OBJCOPY) --version | head -n1
	$(CC) --version | head -n1
	$(AS) --version | head -n1
	python -V | head -n1

clean:
	rm -f *.elf
	rm -f *.bin
	rm -f $(c_objects)
	rm -f hello.s
	rm -f cheri-io.s
	rm -f $(HEX_FILES)
	rm -f $(BSIM_TARGETS)
	rm -f $(VERILOG_TARGETS)
