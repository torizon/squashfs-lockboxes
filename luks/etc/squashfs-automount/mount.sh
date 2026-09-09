#!/bin/ash
# Open a LUKS2 file container with an on-device keyfile, then mount squashfs from the mapper.
# Always exit 0 so RemainAfterExit holds until udev stops the unit on unplug.
# BusyBox ash compatible (no bashisms).
trap 'exit 0' EXIT

CONFIG=/etc/squashfs-automount/config
MEDIA_ROOT=/var/rootdirs/media

log() { logger -t squashfs-automount "$*"; echo "squashfs-automount: $*" >&2; }

if [ ! -r "$CONFIG" ]; then
    log "missing config $CONFIG"
    exit 0
fi
. "$CONFIG"

if [ -z "${IMAGE_NAME:-}" ] || [ -z "${KEYFILE:-}" ] || [ -z "${MAPPER_NAME:-}" ] || [ -z "${MOUNTPOINT:-}" ]; then
    log "config incomplete"
    exit 0
fi
: "${SETTLE_TIMEOUT_SEC:=30}"

if [ ! -r "$KEYFILE" ]; then
    log "keyfile not found at $KEYFILE — install luks.key then replug USB"
    exit 0
fi

if mountpoint -q "$MOUNTPOINT" 2>/dev/null; then
    log "already mounted at $MOUNTPOINT"
    exit 0
fi

deadline=$(( $(date +%s) + SETTLE_TIMEOUT_SEC ))
image=""

while [ "$(date +%s)" -lt "$deadline" ]; do
    for cand in "$MEDIA_ROOT"/*/"$IMAGE_NAME"; do
        [ -f "$cand" ] || continue
        case "$cand" in
            "$MOUNTPOINT"/*) continue ;;
        esac
        image=$cand
        break 2
    done
    sleep 0.5
done

if [ -z "$image" ]; then
    log "no $IMAGE_NAME under $MEDIA_ROOT after ${SETTLE_TIMEOUT_SEC}s"
    exit 0
fi

# Close a stale mapping from a previous attempt
if [ -e "/dev/mapper/$MAPPER_NAME" ]; then
    cryptsetup close "$MAPPER_NAME" 2>/dev/null || true
fi

log "opening LUKS $image -> $MAPPER_NAME"
if ! cryptsetup open --key-file="$KEYFILE" --readonly "$image" "$MAPPER_NAME"; then
    log "cryptsetup open FAILED for $image"
    exit 0
fi

mkdir -p "$MOUNTPOINT"
if ! mount -t squashfs -o ro "/dev/mapper/$MAPPER_NAME" "$MOUNTPOINT"; then
    log "mount failed for /dev/mapper/$MAPPER_NAME"
    cryptsetup close "$MAPPER_NAME" 2>/dev/null || true
    exit 0
fi
log "mounted /dev/mapper/$MAPPER_NAME -> $MOUNTPOINT"
exit 0
