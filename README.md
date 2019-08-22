# Documentation, demos and examples from [Jonathan Cross](https://jonathancross.com).

* [Diceware Entropy Improvement](Diceware-Entropy-Improvement.md) - Add entropy to offline passphrase generation -- don't trust your dice!
* [OpenBSD release key PGP signature](OpenBSD_release_key_PGP_signature.md) - How to verify the OpenBSD 6.4 release signing key using PGP web of trust.
* [OpenBSD verification](OpenBSD_verification.md) - Verify OpenBSD install files from Linux or Mac.
* [Homebrew and OpenPGP signatures](Homebrew_GPG.md) - Information about how the MacOs `brew` command verifies packages.
* [Using an ssh tunnel to connect to a full node](ssh_tunnel_to_full_node.md) - Connect to a remote Monero or Bitcoin node through a secure tunnel.
* [Bitcoin mobile privacy](Bitcoin_mobile_privacy.md) - Improve your mobile client privacy & security via Tor and a Bitcoin full node.
* [Java strong crypto test](java-strong-crypto-test) - Test if you have strong crypto support for Java enabled.
* [Git Cheat Sheet](Git-CheatSheet.md) - Notes on how to configure and use Git / GitHub.
* [Mac OSX Notes](Mac%20OSX%20Notes.md) - General notes on useful configuration options for Mac OSX.
* [Secure PGP keys and Yubikey NEO](Secure%20PGP%20keys%20and%20Yubikey%20NEO.md) - Notes on GPG and YubiKey NEO setup.
* [Software Hashes](Software_Hashes.md) - A collection of SHA-256 software hashes.
* [gpg.conf](gpg.conf) - Example "hardened" configuration file for GnuPG with secure defaults.
* [gnupg.md](gnupg.md) - Everything you ever wanted to know about gpg.  Source for https://gpg.wtf

### Scripts

* [BIP39_Seed_Phrase_Checksum.py](BIP39_Seed_Phrase_Checksum.py) - Calculate the final word (checksum) of a 24 word BIP39 seed phrase.  Useful in combination with [diceware](https://github.com/taelfrinn/Bip39-diceware).
* [gpg-keys-signed-by.pl](gpg-keys-signed-by.pl) - Search for PGP keys in your local keychain signed by a given key.
* [send-pgp-keys.sh](send-pgp-keys.sh) - Upload your GPG public key to multiple services after a change.  Supports [keybase](https://keybase.io), public keyservers and / or your own web server.
* [upgrade-monero.sh](upgrade-monero.sh) - Script used to upgrade installed version of the [Monero](https://getmonero.org) daemon.
* [search-pgp-wot](search-pgp-wot) - Check all signatures on a given PGP key looking for any in the Web Of Trust.

### License

WTFPL - See [LICENSE](https://github.com/jonathancross/jc-docs/blob/master/LICENSE) for more info.
