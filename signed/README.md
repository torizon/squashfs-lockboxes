# Variant: detached OpenSSL signature

Verifies `torizon-lockbox.squashfs.sig` with an on-device PEM public key before mounting. This pays a performance penalty: the device must verify the hash of the entire image before mounting it. Lockboxes already contain signed material using the Uptane protocol, so this integrity check of the image is not necessary for ensuring the integrity of the update itself.

The reason you might choose to implement thisvariant is to protect against an attacker being able to auto-mount a squashfs filesystem; there have been kernel CVEs in the past that targeted the squashfs driver.

## Setup on device

```sh
sudo ./install.sh
sudo cp pubkey.pem /etc/squashfs-automount/pubkey.pem
sudo chmod 644 /etc/squashfs-automount/pubkey.pem
```

Without the public key, or with an invalid signature, the image is not mounted.

## USB contents

```text
torizon-lockbox.squashfs
torizon-lockbox.squashfs.sig
```

## Host: sign the image

```sh
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out payload-priv.pem
openssl pkey -in payload-priv.pem -pubout -out pubkey.pem
mksquashfs ./lockbox-dir torizon-lockbox.squashfs -comp gzip
openssl dgst -sha256 -sign payload-priv.pem -out torizon-lockbox.squashfs.sig torizon-lockbox.squashfs
```

Keep `payload-priv.pem` off the device. Use gzip only for squashfs compression; Torizon OS doesn't support other modes.
