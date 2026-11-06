#include "uart.h"

#include "vdev/vdev.h"
#include "system/x86/ins/io.h"
#include "system/x86/ins/control.h"
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#define UART_THR(base) ((base) + 0)
#define UART_RBR(base) ((base) + 0)
#define UART_DLL(base) ((base) + 0)
#define UART_IER(base) ((base) + 1)
#define UART_DLM(base) ((base) + 1)
#define UART_FCR(base) ((base) + 2)
#define UART_LCR(base) ((base) + 3)
#define UART_MCR(base) ((base) + 4)
#define UART_LSR(base) ((base) + 5)

static inline bool uart_is_transmit_empty(uint16_t base) { return (inb(UART_LSR(base)) & 0x20) != 0; }
static inline bool uart_is_data_ready(uint16_t base) { return (inb(UART_LSR(base)) & 0x01) != 0; }

static int64_t uart_write(struct vdev_io *self, const void *buf, size_t size) {
	uint16_t port = (uint16_t)(uint64_t)self->priv;
	const char *data = (const char *)buf;

	for (size_t i = 0; i < size; i++) {
		while (!uart_is_transmit_empty(port)) { pause(); }
		outb(UART_THR(port), data[i]);
	}

	return (int64_t)size;
}

static int64_t uart_read(struct vdev_io *self, void *buf, size_t size) {
	uint16_t port = (uint16_t)(uint64_t)self->priv;
	char *data = (char *)buf;

	for (size_t i = 0; i < size; i++) {
		while (!uart_is_data_ready(port)) { pause(); }
		data[i] = inb(UART_RBR(port));
	}

	return (int64_t)size;
}

void uart_init(struct vdev_io *dev, uint16_t port, uint32_t baud_rate) {
	outb(UART_IER(port), 0x00);
	outb(UART_LCR(port), 0x80);

	uint16_t divisor = 115200 / baud_rate;

	outb(UART_DLL(port), (uint8_t)(divisor & 0xFF));
	outb(UART_DLM(port), (uint8_t)((divisor >> 8) & 0xFF));
	outb(UART_LCR(port), 0x03);
	outb(UART_FCR(port), 0xC7);
	outb(UART_MCR(port), 0x0B);

	dev->write = uart_write;
	dev->read = uart_read;
	dev->priv = (void *)(uint64_t)port;
}
