#pragma once

#include <stdint.h>
#include <stddef.h>

// sink

struct vdev_sink {
	int64_t (*write)(struct vdev_sink *self, const void *buf, size_t size);
	void *priv;
};

static inline int64_t vdev_sink_write(struct vdev_sink *vdev, const void *buf, size_t size) {
	if (!vdev || !vdev->write) return -1;
	return vdev->write(vdev, buf, size);
}

// io

struct vdev_io {
	int64_t (*write)(struct vdev_io *self, const void *buf, size_t size);
	int64_t (*read)(struct vdev_io *self, void *buf, size_t size);
	void *priv;
};

static inline int64_t vdev_io_write(struct vdev_io *vdev, const void *buf, size_t size) {
	if (!vdev || !vdev->write) return -1;
	return vdev->write(vdev, buf, size);
}

static inline int64_t vdev_io_read(struct vdev_io *vdev, void *buf, size_t size) {
	if (!vdev || !vdev->read) return -1;
	return vdev->read(vdev, buf, size);
}
