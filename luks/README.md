# Variant: LUKS2-encrypted container

USB carries a LUKS2 file whose plaintext is a squashfs filesystem. The device holds a keyfile; without it the container will not open.

**Threat model note:** the keyfile resides on the device (like a decryption key, not a public verify key). This protects the media at rest against someone who has the stick but not the device keyfile. See the note in the main README about options for securing the on-device key.

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
# 1. squashfs 
mksquashfs ./lockbox-dir torizon-lockbox.squashfs -comp gzip

# 2. keyfile
dd if=/dev/urandom of=luks.key bs=64 count=1

# 3. LUKS container large enough for header + squashfs
SQUASH_BYTES=$(wc -c < torizon-lockbox.squashfs)
# ~16-32MiB LUKS2 header headroom + payload
dd if=/dev/zero of=torizon-lockbox.luks bs=1M count=$(( SQUASH_BYTES / 1048576 + 32 ))

cryptsetup luksFormat --type luks2 --key-file=luks.key --batch-mode torizon-lockbox.luks
cryptsetup open --key-file=luks.key torizon-lockbox.luks lockbox
dd if=torizon-lockbox.squashfs of=/dev/mapper/lockbox bs=4M status=progress
cryptsetup close lockbox
```

Copy `luks.key` only to the device, not the USB stick. (See note in main README about secure storage options.) Put `torizon-lockbox.luks` on the USB stick.

## Notes on KDF constraints on embedded devices

LUKS2 defaults to **Argon2**, a memory-hard KDF. `luksFormat` may pick a cost of ~200MiB+; on a board with limited free RAM, unlock can warn (`keyslot operation could fail as it requires more than available memory`) or fail under memory pressure.

Tune at format time for the target device, for example:

```sh
# Lower Argon2 memory cost (KiB), e.g. 32MiB:
cryptsetup luksFormat --type luks2 --key-file=luks.key --batch-mode \
  --pbkdf argon2id --pbkdf-memory 32768 torizon-lockbox.luks

# Or use PBKDF2 (CPU-hard, not memory-hard):
cryptsetup luksFormat --type luks2 --key-file=luks.key --batch-mode \
  --pbkdf pbkdf2 torizon-lockbox.luks
```
