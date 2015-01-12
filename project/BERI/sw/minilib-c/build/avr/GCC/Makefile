###############################################################################
# Makefile for the project mini
###############################################################################

## Path
COMMON_PATH = ../../..
LIB_PATH = $(COMMON_PATH)/lib/avr/GCC

## General Flags
PROJECT = mini
MCU = atmega32
TARGET = mini.elf
LIB_TARGET = $(LIB_PATH)/libmini.a
CC = avr-gcc
AR = avr-ar

CPP = avr-g++

## Options common to compile, link and assembly rules
COMMON = -mmcu=$(MCU)

## Compile options common for all C compilation units.
CFLAGS = $(COMMON)
CFLAGS += -Wall -gdwarf-2 -std=gnu99 -Os   
CFLAGS += -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums -ffunction-sections -fdata-sections
CFLAGS += -D__AVR__ -DPREFER_SIZE_OVER_SPEED 
CFLAGS += -MD -MP -MT $(*F).o -MF dep/$(@F).d 

## Assembly specific flags
ASMFLAGS = $(COMMON)
ASMFLAGS += $(CFLAGS)
ASMFLAGS += -x assembler-with-cpp -Wa,-gdwarf2

## Linker flags
LDFLAGS = $(COMMON)
LDFLAGS +=  -Wl,-Map=mini.map -Wl,--gc-sections


## Intel Hex file production flags
HEX_FLASH_FLAGS = -R .eeprom -R .fuse -R .lock -R .signature

HEX_EEPROM_FLAGS = -j .eeprom
HEX_EEPROM_FLAGS += --set-section-flags=.eeprom="alloc,load"
HEX_EEPROM_FLAGS += --change-section-lma .eeprom=0 --no-change-warnings

## Include Directories
INCLUDES = -I$(COMMON_PATH)/include 

## Objects that must be built in order to link
LIB_OBJECTS = toupper.o isalnum.o isalpha.o isascii.o isblank.o iscntrl.o isdigit.o islower.o isprint.o ispunct.o isspace.o isupper.o isxdigit.o toascii.o tolower.o scanf.o fgetc.o fgets.o fputc.o fputs.o getchar.o printf.o putchar.o strtol.o abs.o assert.o atoi.o atol.o calloc.o div.o exit.o ldiv.o malloc.o rand.o strupr.o bcmp.o bcopy.o bzero.o index.o memccpy.o memchr.o memcmp.o memcpy.o memmove.o mempcpy.o memset.o rindex.o strcat.o strchr.o strcmp.o strcoll.o strcpy.o strcspn.o strlcat.o strlcpy.o strlen.o strlwr.o strncat.o strncmp.o strncpy.o strnlen.o strrchr.o strspn.o strstr.o 

OBJECTS = $(LIB_OBJECTS) test.o test_ctype.o test_stdio.o test_stdlib.o test_string.o syscalls.o

## Objects explicitly added by the user
LINKONLYOBJECTS = 

## Build
all: $(TARGET) $(LIB_TARGET) size

## Compile
test.o: ../../test.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

test_ctype.o: ../../test_ctype.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

test_stdio.o: ../../test_stdio.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

test_stdlib.o: ../../test_stdlib.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

test_string.o: ../../test_string.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<
	
syscalls.o: $(COMMON_PATH)/syscalls_template/syscalls.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

toupper.o: $(COMMON_PATH)/ctype/toupper.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

isalnum.o: $(COMMON_PATH)/ctype/isalnum.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

isalpha.o: $(COMMON_PATH)/ctype/isalpha.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

isascii.o: $(COMMON_PATH)/ctype/isascii.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

isblank.o: $(COMMON_PATH)/ctype/isblank.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

iscntrl.o: $(COMMON_PATH)/ctype/iscntrl.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

isdigit.o: $(COMMON_PATH)/ctype/isdigit.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

islower.o: $(COMMON_PATH)/ctype/islower.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

isprint.o: $(COMMON_PATH)/ctype/isprint.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

ispunct.o: $(COMMON_PATH)/ctype/ispunct.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

isspace.o: $(COMMON_PATH)/ctype/isspace.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

isupper.o: $(COMMON_PATH)/ctype/isupper.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

isxdigit.o: $(COMMON_PATH)/ctype/isxdigit.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

toascii.o: $(COMMON_PATH)/ctype/toascii.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

tolower.o: $(COMMON_PATH)/ctype/tolower.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

scanf.o: $(COMMON_PATH)/stdio/scanf.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

fgetc.o: $(COMMON_PATH)/stdio/fgetc.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

fgets.o: $(COMMON_PATH)/stdio/fgets.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

fputc.o: $(COMMON_PATH)/stdio/fputc.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

fputs.o: $(COMMON_PATH)/stdio/fputs.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

getchar.o: $(COMMON_PATH)/stdio/getchar.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

printf.o: $(COMMON_PATH)/stdio/printf.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

putchar.o: $(COMMON_PATH)/stdio/putchar.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strtol.o: $(COMMON_PATH)/stdlib/strtol.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

abs.o: $(COMMON_PATH)/stdlib/abs.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

assert.o: $(COMMON_PATH)/stdlib/assert.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

atoi.o: $(COMMON_PATH)/stdlib/atoi.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

atol.o: $(COMMON_PATH)/stdlib/atol.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

calloc.o: $(COMMON_PATH)/stdlib/calloc.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

div.o: $(COMMON_PATH)/stdlib/div.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

exit.o: $(COMMON_PATH)/stdlib/exit.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

ldiv.o: $(COMMON_PATH)/stdlib/ldiv.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

malloc.o: $(COMMON_PATH)/stdlib/malloc.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

rand.o: $(COMMON_PATH)/stdlib/rand.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strupr.o: $(COMMON_PATH)/string/strupr.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

bcmp.o: $(COMMON_PATH)/string/bcmp.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

bcopy.o: $(COMMON_PATH)/string/bcopy.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

bzero.o: $(COMMON_PATH)/string/bzero.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

index.o: $(COMMON_PATH)/string/index.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

memccpy.o: $(COMMON_PATH)/string/memccpy.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

memchr.o: $(COMMON_PATH)/string/memchr.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

memcmp.o: $(COMMON_PATH)/string/memcmp.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

memcpy.o: $(COMMON_PATH)/string/memcpy.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

memmove.o: $(COMMON_PATH)/string/memmove.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

mempcpy.o: $(COMMON_PATH)/string/mempcpy.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

memset.o: $(COMMON_PATH)/string/memset.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

rindex.o: $(COMMON_PATH)/string/rindex.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strcat.o: $(COMMON_PATH)/string/strcat.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strchr.o: $(COMMON_PATH)/string/strchr.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strcmp.o: $(COMMON_PATH)/string/strcmp.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strcoll.o: $(COMMON_PATH)/string/strcoll.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strcpy.o: $(COMMON_PATH)/string/strcpy.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strcspn.o: $(COMMON_PATH)/string/strcspn.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strlcat.o: $(COMMON_PATH)/string/strlcat.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strlcpy.o: $(COMMON_PATH)/string/strlcpy.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strlen.o: $(COMMON_PATH)/string/strlen.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strlwr.o: $(COMMON_PATH)/string/strlwr.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strncat.o: $(COMMON_PATH)/string/strncat.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strncmp.o: $(COMMON_PATH)/string/strncmp.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strncpy.o: $(COMMON_PATH)/string/strncpy.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strnlen.o: $(COMMON_PATH)/string/strnlen.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strrchr.o: $(COMMON_PATH)/string/strrchr.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strspn.o: $(COMMON_PATH)/string/strspn.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

strstr.o: $(COMMON_PATH)/string/strstr.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

##Link
$(TARGET): $(OBJECTS)
	 $(CC) $(LDFLAGS) $(OBJECTS) $(LINKONLYOBJECTS) $(LIBDIRS) $(LIBS) -o $(TARGET)

$(LIB_TARGET): $(LIB_OBJECTS)
	 $(AR) rcs $(LIB_TARGET) $(LIB_OBJECTS) 
	 
size: ${TARGET}
	@echo
	@avr-size -C --mcu=${MCU} ${TARGET}
	@avr-size -A -d --mcu=${MCU} ${TARGET}
	@avr-size -B -d --mcu=${MCU} ${LIB_TARGET}

## Clean target
.PHONY: clean
clean:
	-rm -rf $(OBJECTS) mini.elf dep/* mini.map


## Other dependencies
-include $(shell mkdir dep 2>/dev/null) $(wildcard dep/*)

