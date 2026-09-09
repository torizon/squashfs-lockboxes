# Squashfs lockbox automount for Torizon

Automount a fixed-name squashfs from USB at a stable path for Torizon Offline Updates. 

Variants demonstrate how to add signature verification before filesystem mount and how to add encryption.

## Variants

| Directory | Integrity / confidentiality | USB contents | Device secret |
|-----------|------------------------------|--------------|---------------|
| [`none/`](none/) | None — mount if present | `torizon-lockbox.squashfs` | — |
| [`signed/`](signed/) | Detached OpenSSL signature (as on this device) | `torizon-lockbox.squashfs`, `torizon-lockbox.squashfs.sig` | Public key |
| [`luks/`](luks/) | LUKS2 encryption | `torizon-lockbox.luks` | Keyfile |

## Requirements

Common: `ash`, `mount`/`umount`, `mountpoint`, `systemctl`, `udevadm`, `usermount`/`udisks2`, squashfs (`fs-squashfs` autoload).

- **signed:** `openssl`
- **luks:** `cryptsetup` 2.7+, `dm-crypt` + `dm-mod` kernel modules

All these should be available on all Torizon 7 releases, but this has only been specifically validated against Torizon 7.7.0.

## Quick start

```sh
cd signed    # or none / luks
sudo ./install.sh
# then install the variant-specific secret (see that variant's README)
```

Point Aktualizr’s offline-update / lockbox path at `/mnt/squashfs-lockbox`.

## Design notes (all variants)

- Path unit watches for `/var/rootdirs/media/*/torizon-lockbox.squashfs`; `usermount` mounts the USB volume first.
- Mount script always exits 0 + `RemainAfterExit=yes` so a sticky path condition does not restart-loop the service.
- Udev stops the service on USB partition remove (unmount / close). Note that this isn't completely resilient to unplugging a _different_ USB stick while an update is in progress; this would cause the squashfs loop mount to briefly unmount and then come back, and might cause a failed installation, depending on where in the process aktualizr was. Avoid unplugging other USB mass storage devices while an update is in progress.
- Scripts are BusyBox ash (`#!/bin/ash`), to ensure compatibility with non-GPLv3 Torizon variants.
- Torizon now has support for saving the logs of 
