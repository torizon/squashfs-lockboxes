# Variant: LUKS2-encrypted container

USB carries a LUKS2 file whose plaintext is a squashfs filesystem. The device holds a keyfile; without it the container will not open.

Validated on this Torizon image: `cryptsetup` 2.7.5, `dm-crypt` + `dm-mod` modules, open/close of a file-backed LUKS2 container with `--key-file`.

**Threat model note:** the keyfile resides on the device (like a decryption key, not a public verify key). This protects the media at rest against someone who has the stick but not the device keyfile. It does not replace code-signing trust the way the `signed/` variant does.

## Setup on device

```sh
sudo ./install.sh
sudo cp luks.key /etc/squashfs-automount/luks.key
sudo chmod 600 /etc/squashfs-automount/luks.key
```

## USB contents

```text
torizon-lockbox.luks
```

## Host: build encrypted image

```sh
# 1. squashfs (gzip if target kernel is zlib-only)
mksquashfs ./lockbox-dir torizon-lockbox.squashfs -comp gzip

# 2. keyfile
dd if=/dev/urandom of=luks.key bs=64 count=1

# 3. LUKS container large enough for header + squashfs
SQUASH_BYTES=$(wc -c < torizon-lockbox.squashfs)
# ~16–32MiB LUKS2 header headroom + payload
dd if=/dev/zero of=torizon-lockbox.luks bs=1M count=$(( SQUASH_BYTES / 1048576 + 32 ))

cryptsetup luksFormat --type luks2 --key-file=luks.key --batch-mode torizon-lockbox.luks
cryptsetup open --key-file=luks.key torizon-lockbox.luks lockbox
dd if=torizon-lockbox.squashfs of=/dev/mapper/lockbox bs=4M status=progress
cryptsetup close lockbox
```

Copy `luks.key` only to the device; put `torizon-lockbox.luks` on the USB stick.
