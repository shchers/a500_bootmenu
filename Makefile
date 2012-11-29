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
OUTDIR := $(PWD)/bin
OBJDIR = $(OUTDIR)/obj

ASM_SRC := \
	lib/_ashldi3.S \
	lib/_ashrdi3.S \
	lib/_div0.S \
	lib/_divsi3.S \
	lib/_lshrdi3.S \
	lib/_modsi3.S \
	lib/_udivsi3.S \
	lib/_umodsi3.S \
	start.S

C_SRC := \
	lib/stdlib.c \
	bl_0_03_14.c \
	bootmenu.c \
	ext2fs.c \
	fastboot.c \
	framebuffer.c \
	jpeg.c

OBJS = $(addprefix $(OBJDIR)/,$(C_SRC:.c=.o)) $(addprefix $(OBJDIR)/,$(ASM_SRC:.S=.o))

$(shell mkdir -p $(dir $(OBJS)))
$(if $(shell /bin/pwd $(OBJDIR)),,$(error output directory "$(OUTDIR)" not exist))

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

#Targets
all: $(OUTDIR)/$(BOOTLOADER).bin $(OUTDIR)/$(BOOTLOADER).blob

$(OBJDIR)/%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o : %.S
	$(CC) $(AFLAGS) -c $< -o $@

$(OBJDIR)/bootmenu.elf: $(OBJS)
	$(LD) $(LDFLAGS) -T ld-script -o $(OBJDIR)/bootmenu.elf $(OBJS)

$(OBJDIR)/bootmenu.bin: $(OBJDIR)/bootmenu.elf
	$(OBJCOPY) -O binary $(OBJDIR)/bootmenu.elf -R .note -R .comment -R .bss -S $@

$(OUTDIR)/$(BOOTLOADER).bin: $(OBJDIR)/bootmenu.bin
	cp -f bootloader.bin $@
	dd if=$(OBJDIR)/bootmenu.bin of=$@ bs=1 seek=577536 conv=notrunc status=noxfer
	dd if=font.jpg of=$@ bs=1 seek=622592 conv=notrunc status=noxfer
	dd if=bootlogo.jpg of=$@ bs=1 seek=643072 conv=notrunc status=noxfer
	dd if=/dev/zero of=$@ bs=1 seek=622336 count=256 conv=notrunc status=noxfer

$(OUTDIR)/blobmaker:
	$(HOST_CC) $(HOST_CFLAGS) blobmaker.c -o $@
	
$(OUTDIR)/$(BOOTLOADER).blob: $(OUTDIR)/blobmaker $(OUTDIR)/$(BOOTLOADER).bin
	$(OUTDIR)/blobmaker $(OUTDIR)/$(BOOTLOADER).bin $@

.PHONY: prep

# Removing objects and support tools
clean:
	rm -rf $(OBJDIR)
	rm -f $(OUTDIR)/blobmaker

# Removing all
distclean: clean
	rm -rf $(OUTDIR)

# Upload image to device
flash: $(OUTDIR)/$(BOOTLOADER).bin
#	$(if $(CPUID),,$(error CPUID not defined))
	$(if $(SBK),,$(error SBK not defined))
	$(if $(NVFLASH),,$(error nvflash tool not found))
	$(if $(APX_BOOTLOADER),,$(error APX bootloader not defined "APX_BOOTLOADER"))
	$(if $(BCT_FILE),,$(error BCT file not defined "BCT_FILE"))
	$(if $(FLASHCFG_FILE),,$(error Flash configuration file not defined "FLASHCFG_FILE"))
	$(NVFLASH) --bct $(BCT_FILE) --setbct --configfile $(FLASHCFG_FILE) --bl $(APX_BOOTLOADER) --odmdata 0x300d8011 --sbk $(SBK) --sync --wait
	$(NVFLASH) -r --format_partition 4
	$(NVFLASH) -r --download 4 $(OUTDIR)/$(BOOTLOADER).bin
