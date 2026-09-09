# Squashfs lockbox automount for Torizon

Automount a fixed-name squashfs from USB at a stable path for Torizon Offline Updates. 

Variants demonstrate how to add signature verification before filesystem mount and how to add encryption.

## Variants

| Directory | Integrity / confidentiality | USB contents | Device secret |
|-----------|------------------------------|--------------|---------------|
| [`none/`](none/) | None - mount if present | `torizon-lockbox.squashfs` | - |
| [`signed/`](signed/) | Detached OpenSSL signature | `torizon-lockbox.squashfs`, `torizon-lockbox.squashfs.sig` | Public key |
| [`luks/`](luks/) | LUKS2 encryption | `torizon-lockbox.luks` | Keyfile |

Note that the signed variant isn't necessary to ensure update integrity--Torizon Secure Offline Updates provide very strong integrity protection. The signed variant is just to protect against one single attack vector: attacking the squashfs kernel driver. Setting a squashfs image with a particular name to automount means that an attacker with physical access has a way to cause that kernel driver to parse unverified data. There are no current CVEs present in Torizon OS in the squashfs driver, however. Verifying the whole image before loading also does have a performance cost, so unless you are particularly concerned about the squashfs kernel driver as an attack vector, don't assume you need the signed variant by default.

The encrypted variant serves a more common use case: wanting to protect the confidentiality of the offline update image. Depending on what level of attack on confidentiality you want to protect against, you may wish to check the security design notes for more secure options than a raw key file on disk.

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

Point Aktualizr's offline-update / lockbox path at `/mnt/squashfs-lockbox`. See [the documentation](https://developer.toradex.com/torizon/torizon-platform/torizon-updates/secure-offline-updates/how-to-use-secure-offline-updates-with-torizoncore/) for more details, but this should be just creating the following at `/etc/sota/conf.d/99-offline-updates.toml`:

```
[uptane]
enable_offline_updates =  true
offline_updates_source = "/mnt/squashfs-lockbox"
```

You can also do this all via TorizonCore Builder, either with a tcbuild.yaml file or with the isolate subcommand.

## Capturing offline-update logs

Torizon now has support for saving the logs of offline updates. If you want to make use of that feature, make sure you configure the log-saving location correctly. It can't be relative to the lockbox location (i.e. on the squashfs filesystem) because that filesystem is mounted read-only. If you want to make use of the offline logs feature, you could modify the mount/unmount scripts so they bind-mount the USB media directory at a predictable location--something like this:

```
USB_MOUNTPOINT=/mnt/offline-update-media   # from aktualizr config
usb_root=$(dirname "$image")

mkdir -p "$USB_MOUNTPOINT"
if ! mountpoint -q "$USB_MOUNTPOINT"; then
    mount --bind "$usb_root" "$USB_MOUNTPOINT"
fi
```

(With a similar unmount handler in `umount.sh`.)

## Design notes (all variants)

- Path unit watches for `/var/rootdirs/media/*/torizon-lockbox.squashfs`; `usermount` mounts the USB volume first.
- Mount script always exits 0 + `RemainAfterExit=yes` so a sticky path condition does not restart-loop the service.
- Udev stops the service on USB partition remove (unmount / close). Note that this isn't completely resilient to unplugging a _different_ USB stick while an update is in progress; this would cause the squashfs loop mount to briefly unmount and then come back, and might cause a failed installation, depending on where in the process aktualizr was. Avoid unplugging other USB mass storage devices while an update is in progress.
- Scripts are BusyBox ash (`#!/bin/ash`), to ensure compatibility with non-GPLv3 Torizon variants.
- We don't provide a signed+encrypted variant. This is because the lockbox itself is already signed; signing the squashfs image and verifying it before mounting is just to add defense-in-depth against the possibility of a kernel exploit in the squashfs driver.

## Security

This is demo code. Depending on your threat model, you may wish to leverage platform security features to protect the integrity or confidentiality of the cryptographic assets we use here.

If you are using [secure boot](https://github.com/toradex/meta-toradex-security/blob/scarthgap-7.x.y/docs/README-secure-boot.md) and you evaluate the risk of vulnerabilities in the squashfs driver to be high, you may want to make sure the public key used to sign the squashfs image is in the immutable, signed portion of the image (i.e. under `/usr` rather than `/etc`). See [Root Filesystem Protection on Torizon OS](https://developer.toradex.com/torizon/security/rootfs-protection-on-torizon) for more details.

For the LUKS key, this demo uses a key file stored on disk. A more secure variant of this would be to keep the key file on an [encrypted partition](https://github.com/toradex/meta-toradex-security/blob/scarthgap-7.x.y/docs/README-encryption.md). An even better version, though with higher integration effort, would directly use the key-wrapping functionality of the device's security module (e.g. the CAAM, Edgelock Secure Element, a TPM, OP-TEE, or similar) to wrap and store the shared LUKS key with a device-specific secret, and have LUKS unwrap the key in memory directly.
