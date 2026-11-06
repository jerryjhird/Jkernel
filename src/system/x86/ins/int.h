#pragma once

static inline void sti(void) {
	__asm__ __volatile__("sti");
}

static inline void cli(void) {
	__asm__ __volatile__("cli");
}

static inline void hlt(void) {
	__asm__ __volatile__("hlt");
}
