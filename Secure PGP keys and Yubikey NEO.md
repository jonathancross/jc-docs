Secure PGP keys and YubiKey NEO
===============================

**Objective:** Create a secure OpenPGP keypair, eg: offline master key with subkeys (aka "laptop keys") stored on a YubiKey NEO hardware device for everyday use.

Below is a collection of notes and info that helped me navigate through a jungle of new concepts, jargon, bad UI decisions, broken software, bugs and other obstacles to reach the above goal. – [Jonathan](https://jonathancross.com)

## About the YubiKey NEO
<img align="right" src="images/yubikey-neo-n.jpg" alt="yubikey neo-n"> This is an elegant device with many functions including the ability to store OpenPGP keys and use them to sign, encrypt and / or authenticate.  The keys cannot be extracted from the device.  The OpenPGP java apps that do the signing are Open Source.  **NOTE:** Yubico has released the "upgraded" **YubiKey 4** -- [which I discovered is not open source](https://github.com/Yubico/ykneo-openpgp/issues/2#issuecomment-218436213) and is phasing out the NEO-n.  The maximum key size for the YubiKey NEO is 2048 bits, which is fine for subkeys.  You can of course create a 4096 bit master key which stays offline.

Please note that YubiKey NEO devices issued before 2015-04-14 [contain an insecure OpenPGP applet](https://developers.yubico.com/ykneo-openpgp/SecurityAdvisory%202015-04-14.html).

#### Tutorials and troubleshooting:

* [PGP and SSH keys on a YubiKey NEO](https://www.esev.com/blog/post/2015-01-pgp-ssh-key-on-yubikey-neo/) (Eric Severance) - Primary guide used for this setup.
* [Offline GnuPG Master Key and Subkeys on YubiKey NEO Smartcard](http://blog.josefsson.org/2014/06/23/offline-gnupg-master-key-and-subkeys-on-yubikey-neo-smartcard/) (Simon Josefsson)
* [How to import an existing PGP key to a YubiKey](https://developers.yubico.com/PGP/Importing_keys.html)
* [Why Subkeys do not have a Public key](http://security.stackexchange.com/questions/84132/gpg-detaching-public-subkeys-why-cant-i-do-it)
* [Yubico developer signing keys](https://developers.yubico.com/Software_Projects/Software_Signing.html).
* [Using an OpenPGP SmartCard](http://www.narf.ssji.net/~shtrom/wiki/tips/openpgpsmartcard) (some good troubleshooting info related to Linux, gpg smartcards like the YubiKey, etc)
* [Creating the perfect gpg keypair](https://alexcabal.com/creating-the-perfect-gpg-keypair/)
* [OpenPGP Best Practices ](https://riseup.net/en/gpg-best-practices) (riseup) - Good tips from those who need to do security right.
* [Problems with apps sharing the same token on the Mac](https://gpgtools.tenderapp.com/discussions/problems/50028-macgpg2-scdaemon-pcsc-open-failed-sharing-violation-0x8010000b) (Error: `pcsc_connect failed: sharing violation (0x8010000b)`)

## Using GNU Privacy Guard (gpg) / OpenPGP

See [gnupg.md](https://github.com/jonathancross/jc-docs/blob/master/gnupg.md) for general info about Gnupg, tricks, configuration and usability options.  Also info about the OpenPGP Web Of Trust and signing keys.

### License

WTFPL - See [LICENSE](https://github.com/jonathancross/jc-docs/blob/master/LICENSE) for more info.
