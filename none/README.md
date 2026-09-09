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

Torizon's squashfs module is **zlib/gzip only**, so don't use other forms of compression unless you've done a custom Torizon OS build with those configs enabled.
