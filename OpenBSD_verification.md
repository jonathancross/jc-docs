# How to verify an OpenBSD iso file from Linux or Mac

OpenBSD is considered one of the most secure Operating Systems available today.  It comes with an easy to use verification tool called [signify](https://man.openbsd.org/signify.1) and public keys are already included in each OpenBSD system.  However verifying an iso from a non-OpenBSD system can be quite challenging and there are no instructions on how to do so.  This creates a **chicken-and-egg problem** where you need OpenBSD to be installed in order to verify the files needed to install OpenBSD.

Below are basic instructions that can help new users along this path for OpenBSD version 6.4.

### Install signify

OpenBSD project only signs releases using `signify`, not OpenPGP.

* OpenBSD: already installed
* Linux: `sudo apt-get install signify-openbsd`
* macOS: `brew install signify-osx`

Create a couple aliases to normalize macOS and Linux commands:

    which -s sha256sum || alias sha256sum='shasum --algorithm 256'
    which -s signify || alias signify=signify-openbsd

### Download & verify the v6.4 release key

Download the `openbsd-64-base.pub` "base" key file:

    curl -O https://raw.githubusercontent.com/jpouellet/signify-osx/513db1035eb26e9b8ceb4110c54afcfc045c0730/keys/openbsd-64-base.pub

Ensure it contains the correct key (second line):

```
untrusted comment: openbsd 6.4 base public key
RWQq6XmS4eDAcQW4KsT5Ka0KwTQp2JMOP9V/DR4HTVOL5Bc0D7LeuPwA
```

Then [verify the key is correct via the OpenPGP "Web Of Trust"](OpenBSD_release_key_PGP_signature.md).

### Download the release iso and signature

Example for **amd64**, change if needed:

    curl -# -OO https://cdn.openbsd.org/pub/OpenBSD/6.4/amd64/{SHA256.sig,install64.iso}

Confirm checksums:

    sha256sum {openbsd-64-base.pub,install64.iso,SHA256.sig}

Expected result:

    1307b7e5ff87ea31c54267fa6b9a020a47ba187af3b08adaede03017864afdb3  openbsd-64-base.pub
    81833b79e23dc0f961ac5fb34484bca66386deb3181ddb8236870fa4f488cdd2  install64.iso
    ddd29e021ea7fe451687752b3f4227015ecb811e6f900a8edf3fe20e348018a0  SHA256.sig

### Verify the iso signature

    signify -C -p openbsd-64-base.pub -x SHA256.sig install64.iso

Result:

    Signature Verified
    install64.iso: OK

**Congratulations!**

You can now burn the iso file to a disk or USB stick and install OpenBSD 6.4.

# Notes

### Why download openbsd-64-base.pub

Debian has a package called `signify-openbsd-keys` containing the key we need, but it doesn't help much.

1. The current "stable" version ("stretch") is hopelessly out of date, however debian "buster" [version](https://packages.debian.org/buster/signify-openbsd-keys) has the key we need.
2. The tool `signify-openbsd` (as it is called in debian) is configured to look for keys (eg `openbsd-64-base.pub`) in `/etc/signify/` instead of the actual location: `/usr/share/signify-openbsd-keys/`.  So we need to specify the key location anyway.

### How do we know signify-osx has the correct key file?

I (Jonathan Cross) have verified they key file and so has the signify-osx project owner.  The key can also be [verified using the OpenPGP web of trust](OpenBSD_release_key_PGP_signature.md). Anyone you know who has OpenBSD installed can also verify.

### How can I verify a version later than 6.4?

You will need to install v6.4, boot it, then grab the correct key from `/etc/signify/`.

## Disclaimer

This document comes with no guarantees, do your own homework. [Feedback](https://github.com/jonathancross/jc-docs/issues/new?title=Feedback:%20OpenBSD_verification) is welcome.

## License

WTFPL - See [LICENSE](LICENSE) for more info.
