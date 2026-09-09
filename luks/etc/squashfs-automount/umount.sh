#!/bin/ash
# Unmount squashfs and close the LUKS mapping.

CONFIG=/etc/squashfs-automount/config
log() { logger -t squashfs-automount "$*"; echo "squashfs-automount: $*" >&2; }

MOUNTPOINT=/mnt/squashfs-lockbox
MAPPER_NAME=squashfs-lockbox
if [ -r "$CONFIG" ]; then
    . "$CONFIG"
fi
: "${MOUNTPOINT:=/mnt/squashfs-lockbox}"
: "${MAPPER_NAME:=squashfs-lockbox}"

if mountpoint -q "$MOUNTPOINT" 2>/dev/null; then
    umount "$MOUNTPOINT" || umount -l "$MOUNTPOINT"
    log "unmounted $MOUNTPOINT"
else
    log "nothing mounted at $MOUNTPOINT"
fi

if [ -e "/dev/mapper/$MAPPER_NAME" ]; then
    cryptsetup close "$MAPPER_NAME"
    log "closed LUKS mapping $MAPPER_NAME"
fi
