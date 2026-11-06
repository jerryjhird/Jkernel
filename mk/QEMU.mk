QEMU_USE_PCSPEAKER ?= false

QEMU_MACHINE ?= q35
QEMU_CORE_COUNT ?= 1

QEMU_CPU_FLAGS := qemu64

GENERIC_QEMU_FLAGS := -display sdl -cpu $(QEMU_CPU_FLAGS) -smp $(QEMU_CORE_COUNT) -m 256M -cdrom $(BOOT_ISO) -boot d -serial stdio
DISK_QEMU_FLAG := -drive file="$(DISK_IMG)",format=raw,index=0,media=disk

MACHINE_ARGS := $(QEMU_MACHINE)
QEMU_AUDIO_FLAGS :=

ifeq ($(QEMU_USE_PCSPEAKER),true)
    MACHINE_ARGS := $(MACHINE_ARGS),pcspk-audiodev=snd0
    QEMU_AUDIO_FLAGS := -audiodev sdl,id=snd0
endif

GENERIC_QEMU_FLAGS += -machine $(MACHINE_ARGS)
DEBUG_QEMU_FLAGS := -S -s 

.PHONY: runu runb

runu:
	qemu-system-x86_64 -bios $(QEMU_UEFI_FIRMWARE) $(GENERIC_QEMU_FLAGS) $(DISK_QEMU_FLAG) $(QEMU_AUDIO_FLAGS)

runb:
	qemu-system-x86_64 $(GENERIC_QEMU_FLAGS) $(DISK_QEMU_FLAG) $(QEMU_AUDIO_FLAGS)

run-debugu:
	qemu-system-x86_64 $(DEBUG_QEMU_FLAGS) -bios $(QEMU_UEFI_FIRMWARE) $(GENERIC_QEMU_FLAGS) $(DISK_QEMU_FLAG) $(QEMU_AUDIO_FLAGS)

run-debugb:
	qemu-system-x86_64 $(DEBUG_QEMU_FLAGS) $(GENERIC_QEMU_FLAGS) $(DISK_QEMU_FLAG) $(QEMU_AUDIO_FLAGS)
