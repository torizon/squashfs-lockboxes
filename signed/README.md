# Variant: detached OpenSSL signature

Verifies `torizon-lockbox.squashfs.sig` with an on-device PEM public key before mounting. Matches the implementation developed on this device.

## Setup on device

```sh
sudo ./install.sh
sudo cp pubkey.pem /etc/squashfs-automount/pubkey.pem
sudo chmod 644 /etc/squashfs-automount/pubkey.pem
```

Without the public key, the image is not mounted.

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

Keep `payload-priv.pem` off the device. Use gzip if the target kernel squashfs is zlib-only (as on this Torizon image).
