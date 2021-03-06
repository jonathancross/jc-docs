# OpenPGP / Gnupg related scripts and documentation

* [Secure PGP keys and Yubikey NEO](Secure%20PGP%20keys%20and%20Yubikey%20NEO.md) - Notes on GPG and YubiKey NEO setup.
* [gpg.conf](gpg.conf) - Example "hardened" configuration file for GnuPG with secure defaults.
* [gnupg.md](gnupg.md) - Everything you ever wanted to know about gpg.  Source for https://gpg.wtf
* [gpg-keys-signed-by.pl](gpg-keys-signed-by.pl) - Search for PGP keys in your local keychain signed by a given key.
* [send-pgp-keys.sh](send-pgp-keys.sh) - Upload your GPG public key to multiple services after a change.  Supports [keybase](https://keybase.io), public keyservers and / or your own web server.
* [search-pgp-wot](search-pgp-wot) - Check all signatures on a given PGP key looking for any in the Web Of Trust.
* [email-key-uids.sh](email-key-uids.sh) - Split a signed OpenPGP key into component UIDs and email them to the owner via Apple's Mail.app.
* [OpenBSD release key PGP signature](OpenBSD_release_key_PGP_signature.md) - How to verify the OpenBSD 6.4 release signing key using OpenPGP web of trust.
* [OpenBSD verification](OpenBSD_verification.md) - Verify OpenBSD install files from Linux or Mac.
