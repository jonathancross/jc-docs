# How to verify an OpenBSD iso file from Linux or Mac

OpenBSD is considered one of the most secure Operating Systems available today.  It comes with an easy to use verification tool called [signify](https://man.openbsd.org/signify.1) and public keys are already included in each OpenBSD system.  However verifying from a non-OpenBSD system can be quite challenging and there are no instructions to do so.  This creates a **chicken-and-egg problem** where you need OpenBSD to be installed in order to verify the files needed to install OpenBSD.

Below are basic instructions that can help new users along this path for OpenBSD version 6.4.

### Install signify

OpenBSD project only signs releases using `signify`, not OpenPGP.

* OpenBSD: already installed
* Linux: `sudo apt-get install signify-openbsd`
* macOS: `brew install signify-osx`

### Make the release key file

The OpenBSD "base" release key for [v6.4](https://www.openbsd.org/64.html) is `RWQq6XmS4eDAcQW4KsT5Ka0KwTQp2JMOP9V/DR4HTVOL5Bc0D7LeuPwA`.  This can be [verified via the PGP "Web Of Trust" using my instructions here](OpenBSD_release_key_PGP_signature.md).

Download the [openbsd-64-base.pub](https://raw.githubusercontent.com/jpouellet/signify-osx/513db1035eb26e9b8ceb4110c54afcfc045c0730/keys/openbsd-64-base.pub) key and ensure it contains the correct key (second line):
```
untrusted comment: openbsd 6.4 base public key
RWQq6XmS4eDAcQW4KsT5Ka0KwTQp2JMOP9V/DR4HTVOL5Bc0D7LeuPwA
```
(See [Why download openbsd-64-base.pub](#why-download-openbsd-64-basepub) for more info)

### Download the release, hashes & signatures

Example for **amd64**, change if needed:

You can manually download [install64.iso](https://cdn.openbsd.org/pub/OpenBSD/6.4/amd64/install64.iso), [SHA256](https://cdn.openbsd.org/pub/OpenBSD/6.4/amd64/SHA256) and [SHA256.sig](https://cdn.openbsd.org/pub/OpenBSD/6.4/amd64/SHA256.sig). 

Or use wget if you have it installed:

    wget https://cdn.openbsd.org/pub/OpenBSD/6.4/amd64/install64.iso
    wget https://cdn.openbsd.org/pub/OpenBSD/6.4/amd64/SHA256
    wget https://cdn.openbsd.org/pub/OpenBSD/6.4/amd64/SHA256.sig

You should now have these 4 files:

    344M install64.iso
    4.0K openbsd-64-base.pub
    4.0K SHA256
    4.0K SHA256.sig

### Check the signatures

On Linux, use signify-openbsd:

    signify-openbsd -C -p openbsd-64-base.pub -x SHA256.sig install64.iso

On macOS, use signify:

    signify -C -p openbsd-64-base.pub -x SHA256.sig install64.iso

Result:

    Signature Verified
    install64.iso: OK


### Why download openbsd-64-base.pub

Debian has a package called `signify-openbsd-keys` containing the key we need, but it doesn't help much.

1. The current "stable" version ("stretch") is hopelessly out of date, however debian "buster" [version](https://packages.debian.org/buster/signify-openbsd-keys) has the key we need.
2. The tool `signify-openbsd` (as it is called in debian) is configured to look for keys (eg `openbsd-64-base.pub`) in `/etc/signify/` instead of the actual location: `/usr/share/signify-openbsd-keys/`.  So we need to specify the key location anyway.

## Disclaimer

This document comes with no guarantees, do your own homework. [Feedback](https://github.com/jonathancross/jc-docs/issues/new?title=Feedback:%20OpenBSD%20verification) is welcome.

## License

WTFPL - See [LICENSE](LICENSE) for more info.
