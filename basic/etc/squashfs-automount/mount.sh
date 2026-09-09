#!/bin/ash
# Loop-mount squashfs from USB. No integrity check.
# Always exit 0 so RemainAfterExit holds until udev stops the unit on unplug.
trap 'exit 0' EXIT

CONFIG=/etc/squashfs-automount/config
MEDIA_ROOT=/var/rootdirs/media

log() { logger -t squashfs-automount "$*"; echo "squashfs-automount: $*" >&2; }

if [ ! -r "$CONFIG" ]; then
    log "missing config $CONFIG"
    exit 0
fi
. "$CONFIG"

if [ -z "${IMAGE_NAME:-}" ] || [ -z "${MOUNTPOINT:-}" ]; then
    log "config incomplete"
    exit 0
fi
: "${SETTLE_TIMEOUT_SEC:=30}"

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

mkdir -p "$MOUNTPOINT"
if ! mount -t squashfs -o loop,ro "$image" "$MOUNTPOINT"; then
    log "mount failed for $image"
    exit 0
fi
log "mounted $image -> $MOUNTPOINT"
exit 0
