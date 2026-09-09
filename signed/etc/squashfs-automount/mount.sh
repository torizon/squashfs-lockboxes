#!/bin/ash
# Verify a detached OpenSSL signature, then loop-mount the squashfs image.
# Always exit 0 so RemainAfterExit holds until udev stops the unit on unplug.
# No set -e / pipefail: those can still abort with non-zero and reintroduce the loop.
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

if [ -z "${IMAGE_NAME:-}" ] || [ -z "${SIG_SUFFIX:-}" ] || [ -z "${PUBKEY:-}" ] || [ -z "${MOUNTPOINT:-}" ]; then
    log "config incomplete"
    exit 0
fi
: "${SETTLE_TIMEOUT_SEC:=30}"

if [ ! -r "$PUBKEY" ]; then
    log "public key not found at $PUBKEY — install pubkey.pem then replug USB"
    exit 0
fi

if mountpoint -q "$MOUNTPOINT" 2>/dev/null; then
    log "already mounted at $MOUNTPOINT"
    exit 0
fi

deadline=$(( $(date +%s) + SETTLE_TIMEOUT_SEC ))
image=""
sig=""

while [ "$(date +%s)" -lt "$deadline" ]; do
    for cand in "$MEDIA_ROOT"/*/"$IMAGE_NAME"; do
        [ -f "$cand" ] || continue
        case "$cand" in
            "$MOUNTPOINT"/*) continue ;;
        esac
        if [ -f "${cand}${SIG_SUFFIX}" ]; then
            image=$cand
            sig=${cand}${SIG_SUFFIX}
            break 2
        fi
    done
    sleep 0.5
done

if [ -z "$image" ]; then
    log "no $IMAGE_NAME(+${SIG_SUFFIX}) under $MEDIA_ROOT after ${SETTLE_TIMEOUT_SEC}s"
    exit 0
fi

log "verifying $image with $PUBKEY"
if ! openssl dgst -sha256 -verify "$PUBKEY" -signature "$sig" "$image" >/dev/null; then
    log "signature verification FAILED for $image"
    exit 0
fi
log "signature OK"

mkdir -p "$MOUNTPOINT"
if ! mount -t squashfs -o loop,ro "$image" "$MOUNTPOINT"; then
    log "mount failed for $image"
    exit 0
fi
log "mounted $image -> $MOUNTPOINT"
exit 0
