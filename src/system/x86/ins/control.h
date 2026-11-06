#pragma once

static inline void pause(void) {
	__asm__ __volatile__("pause");
}
