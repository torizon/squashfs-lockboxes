# Variant: no integrity check

Mounts `/media/*/torizon-lockbox.squashfs` at `/mnt/squashfs-lockbox` with no signature or encryption check.

## Setup on device

```sh
sudo ./install.sh
```

## USB contents

```text
torizon-lockbox.squashfs
```

## Host: build the image

```sh
# example: pack a lockbox directory (needs mksquashfs on the host)
mksquashfs ./lockbox-dir torizon-lockbox.squashfs -comp gzip
```

Use gzip (or another compressor your target kernel supports). This Torizon image’s squashfs module is **zlib/gzip only**.
