#include "bs.h"

#include <stdint.h>
#include "system/x86/dev/uart.h"
#include "system/x86/ins/int.h"
#include "lib/string.h"

static struct vdev_io dev;

void bootstrap1(void) {
	uart_init(&dev, 0x3F8, 115200);

	char *msg = "hello world\n";
	vdev_io_write(&dev, msg, k_strlen(msg));

	hlt();
}
