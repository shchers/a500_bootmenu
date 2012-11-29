#
# Makefile for bootmenu
#

CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)ld
OBJCOPY := $(CROSS_COMPILE)objcopy

HOST_CC := gcc
HOST_CFLAGS :=

LIBGCC := -L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) -lgcc

CFLAGS := -Os -Wall -Wno-return-type -Wno-main -fno-builtin -fno-stack-protector -mthumb-interwork -march=armv7-a -mthumb -ffunction-sections -Iinclude
AFLAGS := -D__ASSEMBLY__ -fno-builtin -march=armv7-a -ffunction-sections
LDFLAGS := -static $(LIBGCC) -nostdlib --gc-sections 
O ?= .

LIB_OBJS := $(O)/lib/_ashldi3.o $(O)/lib/_ashrdi3.o  $(O)/lib/_div0.o $(O)/lib/_divsi3.o $(O)/lib/_lshrdi3.o $(O)/lib/_modsi3.o  $(O)/lib/_udivsi3.o $(O)/lib/_umodsi3.o $(O)/lib/stdlib.o  
BL_OBJS := $(O)/bl_0_03_14.o $(O)/framebuffer.o $(O)/jpeg.o $(O)/bootmenu.o $(O)/fastboot.o $(O)/ext2fs.o
OBJS := $(O)/start.o $(LIB_OBJS) $(BL_OBJS)

BOOTLOADER := bootloader_v9

# TODO: Implement generating SBK from CPUID
## CPU ID should be defined outside Makefile and will be used for generating SBK
#CPUID :=
SBK :=
# Path to APX bootloader, required for starting download mode
APX_BOOTLOADER :=
# Path to boot config table (BCT) file which was downloaded from device
BCT_FILE :=
# Path to flash configuration file
FLASHCFG_FILE :=
# Path to nVidia flash tool
NVFLASH := $(shell PATH=./:$PATH /usr/bin/which nvflash)

# Attempt to create a output directory.
$(shell [ -d ${O} ] || mkdir -p ${O})

# Verify if it was successful.
OUTPUT_DIR := $(shell cd $(O) && /bin/pwd)
$(if $(OUTPUT_DIR),,$(error output directory "$(O)" does not exist))

#Attempt to create a lib subdirectory
$(shell [ -d ${O}/lib ] || mkdir -p ${O}/lib)

# Verify if it was successful.
OUTPUT_DIR := $(shell cd $(O)/lib && /bin/pwd)
$(if $(OUTPUT_DIR),,$(error output directory "$(O)/lib" does not exist))

#Targets
all: $(O)/$(BOOTLOADER).bin $(O)/$(BOOTLOADER).blob

$(O)/%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(O)/%.o : %.S
	$(CC) $(AFLAGS) -c $< -o $@

$(O)/bootmenu.elf: $(OBJS)
	$(LD) $(LDFLAGS) -T ld-script -o $(O)/bootmenu.elf $(OBJS)

$(O)/bootmenu.bin: $(O)/bootmenu.elf
	$(OBJCOPY) -O binary $(O)/bootmenu.elf -R .note -R .comment -R .bss -S $@

$(O)/$(BOOTLOADER).bin: $(O)/bootmenu.bin
	cp -f bootloader.bin $@
	dd if=$(O)/bootmenu.bin of=$@ bs=1 seek=577536 conv=notrunc
	dd if=font.jpg of=$@ bs=1 seek=622592 conv=notrunc
	dd if=bootlogo.jpg of=$@ bs=1 seek=643072 conv=notrunc
	dd if=/dev/zero of=$@ bs=1 seek=622336 count=256 conv=notrunc

$(O)/blobmaker:
	$(HOST_CC)  $(HOST_CFLAGS) blobmaker.c -o $@
	
$(O)/$(BOOTLOADER).blob: $(O)/blobmaker $(O)/$(BOOTLOADER).bin
	$(O)/blobmaker $(O)/$(BOOTLOADER).bin $@

.PHONY: prep

#Clean
clean:
	rm -f $(OBJS)
	rm -f $(O)/blobmaker
	rm -f $(O)/bootmenu.elf
	rm -f $(O)/bootmenu.bin
	rm -f $(O)/$(BOOTLOADER).bin
	rm -f $(O)/$(BOOTLOADER).blob

flash:
#	$(if $(CPUID),,$(error CPUID not defined))
	$(if $(SBK),,$(error SBK not defined))
	$(if $(NVFLASH),,$(error nvflash tool not found))
	$(if $(APX_BOOTLOADER),,$(error APX bootloader not defined "APX_BOOTLOADER"))
	$(if $(BCT_FILE),,$(error BCT file not defined "BCT_FILE"))
	$(if $(FLASHCFG_FILE),,$(error Flash configuration file not defined "FLASHCFG_FILE"))
	$(NVFLASH) --bct $(BCT_FILE) --setbct --configfile $(FLASHCFG_FILE) --bl $(APX_BOOTLOADER) --odmdata 0x300d8011 --sbk $(SBK) --sync --wait
	$(NVFLASH) -r --format_partition 4
	$(NVFLASH) -r --download 4 $(O)/$(BOOTLOADER).bin
