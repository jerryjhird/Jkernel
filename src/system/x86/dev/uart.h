#pragma once

#include "vdev/vdev.h"

void uart_init(struct vdev_io *dev, uint16_t port, uint32_t baud_rate);
