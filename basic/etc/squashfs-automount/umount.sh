#!/bin/ash
# Unmount the squashfs lockbox mountpoint if present.

CONFIG=/etc/squashfs-automount/config
log() { logger -t squashfs-automount "$*"; echo "squashfs-automount: $*" >&2; }

MOUNTPOINT=/mnt/squashfs-lockbox
if [ -r "$CONFIG" ]; then
    . "$CONFIG"
fi
: "${MOUNTPOINT:=/mnt/squashfs-lockbox}"

if mountpoint -q "$MOUNTPOINT" 2>/dev/null; then
    umount "$MOUNTPOINT" || umount -l "$MOUNTPOINT"
    log "unmounted $MOUNTPOINT"
else
    log "nothing mounted at $MOUNTPOINT"
fi
