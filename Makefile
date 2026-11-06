QEMU_UEFI_FIRMWARE ?= /usr/share/OVMF/OVMF_CODE.fd

SRCDIR := src
BUILDDIR := build/srctree
DISTDIR := dist
CACHEDIR := build/cache
ISO_ROOT := build/iso_root

GIT_LIMINE = "https://github.com/Limine-Bootloader/Limine.git" --depth=1 --branch v11.x-binary
GIT_LIMINE_PROTOCOL = "https://github.com/Limine-Bootloader/limine-protocol.git" --depth=1

LIMINE_DIR := $(CACHEDIR)/limine
LIMINE_PROTOCOL_DIR := $(CACHEDIR)/limine-protocol

ALL_REPOS_DIR := $(LIMINE_DIR) $(LIMINE_PROTOCOL_DIR)

DISK_IMG := $(CACHEDIR)/qemu-disk.img
C_SRCS := $(shell find $(SRCDIR) -name "*.c")
ASM_SRCS := $(shell find $(SRCDIR) -name "*.S")
OBJS := $(C_SRCS:$(SRCDIR)/%.c=$(BUILDDIR)/%.o) $(ASM_SRCS:$(SRCDIR)/%.S=$(BUILDDIR)/%.o)
DEPS := $(OBJS:.o=.d)

KERNEL_ELF := $(DISTDIR)/kernel.elf
BOOT_ISO := $(DISTDIR)/Jkernel.x86-64.iso

CFLAGS_W := -Wno-unused-command-line-argument -Wno-unknown-warning-option -Wall -Wextra -Wpedantic -Wshadow -Wstrict-prototypes -Wmissing-prototypes -Wcast-align -Wmissing-declarations
CFLAGS := -fno-pic -std=gnu11 -O2 -g -ffreestanding -fno-builtin -fno-stack-protector -fno-stack-check -fno-lto -m64 -mcmodel=kernel -mno-red-zone -mno-sse -mno-sse2 -mno-avx -mno-mmx -mno-80387 -mno-bmi -mno-bmi2 -I$(SRCDIR) -I$(LIMINE_PROTOCOL_DIR)/include -I. -MMD -MP $(CFLAGS_W)

LDFLAGS := -T src/kernel.ld -nostdlib -static -z max-page-size=0x1000 -no-pie

.PHONY: all clean run style format compile_commands.json
all: dirs deps_setup $(OBJS) $(KERNEL_ELF) $(DISK_IMG) $(BOOT_ISO) compile_commands.json

dirs:
	@mkdir -p $(DISTDIR) $(CACHEDIR) $(BUILDDIR) $(ISO_ROOT)

$(OBJS): | dirs deps_setup

deps_setup:
	@mkdir -p $(ALL_REPOS_DIR)

	@if [ ! -d "$(LIMINE_DIR)/.git" ]; then \
		git clone $(GIT_LIMINE) $(LIMINE_DIR); \
	fi

	@if [ ! -d "$(LIMINE_PROTOCOL_DIR)/.git" ]; then \
		git clone $(GIT_LIMINE_PROTOCOL) $(LIMINE_PROTOCOL_DIR); \
	fi

	@$(MAKE) -C $(LIMINE_DIR)

compile_commands.json: $(C_SRCS) $(ASM_SRCS)
	@echo "[" > $@
	@comma=""; \

	for src in $(C_SRCS) $(ASM_SRCS); do \
		rel_path="$${src#$(SRCDIR)/}"; \
		obj="$(BUILDDIR)/$${rel_path%.*}.o"; \
		printf "%s\n  {\n    \"directory\": \"%s\",\n    \"command\": \"%s %s -c %s\",\n    \"file\": \"%s\",\n    \"output\": \"%s\"\n  }" \
			"$$comma" "$(CURDIR)" "$(CC)" "$(subst ",\",$(CFLAGS))" "$$src" "$$src" "$$obj" >> $@; \
		comma=","; \
	done

	@printf "\n]\n" >> $@

$(BUILDDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(dir $@)
	@echo " [ $(CC) ] $<"
	@$(CC) $(CFLAGS) -c $< -o $@

$(BUILDDIR)/%.o: $(SRCDIR)/%.S
	@mkdir -p $(dir $@)
	@echo " [ $(CC) ] $<"
	@$(CC) $(CFLAGS) -c $< -o $@

$(DISK_IMG): | dirs
	@echo " [ qemu-img ] $(DISK_IMG)"
	@qemu-img create -f raw $(DISK_IMG) 1024M > /dev/null

$(KERNEL_ELF): $(OBJS) | dirs
	@echo "linking $@"
	@$(CC) $(LDFLAGS) $(OBJS) -o $@
	@cp $@ $(BUILDDIR)/kernel.sym
	@objcopy --strip-debug --strip-unneeded -R .eh_frame -R .note.gnu.property -R .note.gnu.build-id -R .comment $@

$(BOOT_ISO): $(KERNEL_ELF) | dirs
	@echo " [ISO] Generating $@"
	@rm -rf $(ISO_ROOT)/*
	@mkdir -p $(ISO_ROOT)/boot $(ISO_ROOT)/EFI/BOOT

	@cp $(KERNEL_ELF) $(ISO_ROOT)/kernel.elf
	@cp limine.conf $(ISO_ROOT)/limine.conf
	@cp $(LIMINE_DIR)/limine-bios.sys $(LIMINE_DIR)/limine-bios-cd.bin $(ISO_ROOT)/boot/
	@cp $(LIMINE_DIR)/limine-uefi-cd.bin $(ISO_ROOT)/boot/
	@cp $(LIMINE_DIR)/BOOTX64.EFI $(ISO_ROOT)/EFI/BOOT/
	
	@xorriso -as mkisofs -R -J -pad -V "JKERNEL" \
		-b boot/limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot boot/limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label \
		$(ISO_ROOT) -o $@ > /dev/null 2>&1

	@$(LIMINE_DIR)/limine bios-install $@

include mk/ALL.mk

format:
	bash mk/format.bash src/

clean:
	rm -rf $(BUILDDIR) dist

clean-cache: clean
	rm -rf $(CACHEDIR) .cache compile_commands.json

fullclean: clean clean-cache

-include $(DEPS)
