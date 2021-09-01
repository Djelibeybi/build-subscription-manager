# Building `subscription-manager` RPMs on Oracle Linux

This repo contains the `Dockerfile` and `build-rshm.sh` files to automatically
build the appropriate `subscription-manager` RPMs for Oracle Linux 7 and 8.

## Requirements

A host machine that has a relatively recent version of Docker installed. I've
tested this on Oracle Linux, macOS and Windows (using Docker Desktop).

If you want to use GPG to sign the binary RPMs, export your public and private
keys and concatenate them into `./gpg/key.asc` under _both_ `./oraclelinux7` and
`./oraclelinux8`. You will also need to place your key passphrase in `./gpg/passphrase`.

> **NOTE:** remember to delete these files afterwards!

## Building the RPMs

To build the RPMs, replace `Jane Builder` and `jane@builder.com` in the example
below with your actual name and email address as _stored in your GPG key_.
If `GPG_NAME_EMAIL` doesn't match your key, the packages will not be signed.

```shell
export GPG_NAME_EMAIL="Jane Builder <jane@builder.com>
```

Then, build for each version required:

```shell
cd oraclelinux7
./build-rhsm-ol7.sh
```

> **Note:** The RPMs for Oracle Linux 7 are renamed slightly from upstream
> because Oracle obsoletes `subscription-manager`. In this case, the main RPM
> is named `subscription-manager-el7` and it obsoletes all the packages that
> provide Spacewalk and ULN support.

```shell
cd oraclelinux8
./build-rhsm-ol8.sh
```

## License

Copyright (c) 2021 Avi Miller.

Licensed under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>
