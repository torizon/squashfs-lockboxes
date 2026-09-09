#!/bin/ash
# Install this variant onto the running system. Run as root.
# Usage: ./install.sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

if [ "$(id -u)" -ne 0 ]; then
    echo "run as root" >&2
    exit 1
fi

mkdir -p /etc/squashfs-automount /mnt/squashfs-lockbox
cp "$ROOT/etc/squashfs-automount/config" /etc/squashfs-automount/config
cp "$ROOT/etc/squashfs-automount/mount.sh" /etc/squashfs-automount/mount.sh
cp "$ROOT/etc/squashfs-automount/umount.sh" /etc/squashfs-automount/umount.sh
chmod 755 /etc/squashfs-automount/mount.sh /etc/squashfs-automount/umount.sh

cp "$ROOT/etc/systemd/system/squashfs-automount.service" /etc/systemd/system/
cp "$ROOT/etc/systemd/system/squashfs-automount.path" /etc/systemd/system/
cp "$ROOT/etc/udev/rules.d/99-squashfs-automount.rules" /etc/udev/rules.d/

systemctl daemon-reload
systemctl enable --now squashfs-automount.path
udevadm control --reload-rules

echo "installed (base variant). plug in USB with torizon-lockbox.squashfs"
