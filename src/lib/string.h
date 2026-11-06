#pragma once

#include <stddef.h>

static inline size_t k_strlen(const char *s) {
	const char *p = s;
	while (*p != '\0') { p++; }
	return (size_t)(p - s);
}
