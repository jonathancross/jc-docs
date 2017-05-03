Secure PGP keys and YubiKey NEO
===============================

**Objective:** Create a secure OpenPGP keypair, eg: offline master key with subkeys (aka "laptop keys") stored on a YubiKey NEO hardware device for everyday use.

Below is a collection of notes and info that helped me navigate through a jungle of new concepts, jargon, bad UI decisions, broken software, bugs and other obstacles to reach the above goal. – [Jonathan](https://jonathancross.com)

## About the YubiKey NEO
<img align="right" src="images/yubikey-neo-n.jpg" alt="yubikey neo-n"> This is an elegant device with many functions including the ability to store OpenPGP keys and use them to sign, encrypt and / or authenticate.  The keys cannot be extracted from the device.  The OpenPGP java apps that do the signing are Open Source.  **NOTE:** Yubico has released the "upgraded" **YubiKey 4** -- [which I discovered is not open source](https://github.com/Yubico/ykneo-openpgp/issues/2#issuecomment-218436213) and is phasing out the NEO-n which I use.  The maximum key size for the YubiKey NEO is 2048 bits, which is fine for subkeys.  You can of course create a 4096 bit master key which stays offline.

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

#### Things that confused me
*  *Primary Key* = "Master Key"
*  `--armor` = This option causes the key to be output as ASCII (instead of the default binary format).  Why not use `--ascii`?  Furthermore, users will encounter plenty of nonsense if you forget this option while trying to encrypt a message.  ALL of these will fail without a useful error message for example:

        gpg --encrypt
        gpg --encrypt --recipient ja@wikileaks.org
        gpg --encrypt ja@wikileaks.org
        gpg --recipient 92318DBA
* [Why do I see “Secret key is available.” in gpg when it is not?](http://security.stackexchange.com/questions/115230/why-do-i-see-secret-key-is-available-in-gpg-when-it-is-not)
* The command `gpg --armor --export=2FFA7695` will export *ALL* public keys, not just `2FFA7695` as one might expect.  Unlike many other gnu programs, gpg doesn't support the `=` (equals sign) as separator, so it just silently assumes you want everything.
*  By default, `gpg -k` will **not** list fingerprints or the recomended longer key ID format experts agree should be used.  Instead, it lists the [unsafe 8-character "short" format](http://www.asheesh.org/note/debian/short-key-ids-are-bad-news.html).  Why is the default the less secure option?  Use `gpg -k --fingerprint --keyid-format long` instead.
* When you use `gpg --search-keys KEYID`, the command will often not find perfectly valid keys (eg: those on pool.sks-keyservers.net or pgp.mit.edu).  There is a bunch of keyservers, so the key you are looking for *may* be on any of them, or *none of them*, or maybe it is there, but the search algo doesn't find it.
* If you add a picture (must be a jpg!), add a default keyserver, etc. it will be stored as part of your Public key.  Your pub key will be changing often and should be republished.  It is still not clear to me which actions change your Public key:
  * `YES` Adding a jpg photo.
  * `YES` Adding / revoking an identity. (NOTE: identities cannot be *modified*)
  * `YES` Updating the expiration date.
  * `YES` Certifying / adding or revoking a subkey.
  * `YES` Importing a signed copy of your key from someone else.
  * `YES` Adding a keyserver url.
  * `NO` Signing another person's key.
  * `NO` Publishing your Public key to a keyserver.

#### gpg will use various cryptic symbols and abbreviations noting the properties of the key
When listing Secret keys (`gpg --list-secret-keys` or `gpg -K`) you may see:
* `sec` = Secret (aka Private) and Public key exists for the Master key.
* `sec#` = Master key secret is not present, only a "stub" of the private key.  This is normal when using subkeys without their Master key being present.
* `uid` = User ID.  Combination of name, email address and an optional comment.  You can have multiple UIDs, add and remove (`revoke`) them without breaking your Master key.  If you add a photo, it will be a new `uid` added to the key. When people "sign your key", they are really signing one or more of these UIDs.
* `ssb` = Subkey Certified by the master key.
* `ssb>` = Subkey where the private portion is on the YubiKey or another device.

When listing Public keys (`gpg --list-keys` or `gpg -k`) you may see:
* `pub` = Public portion of your Master keypair.
* `sub` = Subkey (you will never actually work with a public key for a Subkey, only the Master).

When editing a key (`gpg --edit-key KEYID`) you may see:
* `sub*` = The star indicates the particular Subkey is selected for editing.
* `sig!3` = You see this after running the `check` command. The number explains the quality of the ID check (see below).

When listing signatures (`gpg --list-sigs KEYID`) you may see:
* `sig `, `sig 1`, `sig 2`, `sig 3` = How thoroughly was the identity claim verified (`sig`=unknown ... `sig 3`=extremely thorough).
Here is [a detailed explanation](http://security.stackexchange.com/a/141508/16036).

There are different types of keys, you can see this on the right as "usage":
* `usage: C` = **Certify** other keys, IE: this is your Master key.
* `usage: S` = **Sign** messages so people know it was sent from you.  This can be a Subkey.
* `usage: E` = **Encrypt** messages to sent to other people.  This can be a Subkey.
* `usage: A` = **Authenticate** yourself, for example when using SSH to log into a server.  This can be a Subkey.

#### Difficulties with offline master key

* As of February 2016, I was not able to find any Linux distribution that could write gpg keys to the YubiKey without additional software being installed.  Therefore you will need to try and transfer all required software to the offline system (complex and could compromise your offline system), or you sacrifice some security and temporarily bring the subkeys onto a system which can easily write to the YubiKey.
  * In my case, I tried to get the device to work using offline Xubuntu, Tails, etc, but was not successful.
  * Instead, I created the master key, then put that into a TrueCrypt container.  Then did the same with a separate container for subkeys.  I then moved the subkey container to a computer with Internet connection turned off, opened it and wrote the subkeys onto the YubiKey device.  I believe the computer was free of malware, but cannot be 100% certain.  The master key is only used on an air-gapped computer, so it is safe and can be used to revoke subkeys if needed.
* I now use [Tails 2.x](https://tails.boum.org/) on a USB stick whenever I need to work with my Master key (eg: sign another user's key).  This works well on my MacBook Air as there is no functioning WiFi driver and furthermore it is effortless to disable networking on boot.

#### Creating stubs on a new computer

1. Import public key.
2. Run `sudo gpg -–card-status`
3. May need to change owner of secure keyring to yourself if it was just created:

        sudo chown $USER ~/.gnupg/secring.gpg
4. Check your work by running `gpg --list-secret-keys`.  If you see `ssb>` for the subkeys, then all is good.

##### Permissions problems

Symptom: `gpg -–card-status` works as root, but not as an unpriviledged user.

    gpg --card-status
    gpg: selecting openpgp failed: unknown command
    gpg: OpenPGP card not available: general error

Workaround: use sudo:

    sudo gpg --card-status

Same with signing, but you need to explicitly add -S

    sudo git commit -a -S


##### UPDATE: 2016-05-03

I have been able to fix `gpg` and `git` signing in Linux Mint 17.3 using `udev` rules:

    sudo sh -c 'wget -q -O - https://raw.githubusercontent.com/Yubico/yubikey-neo-manager/master/resources/linux-fix-ccid-udev | python'

I can then use `git commit -a -S` to sign my commit. NOTE: If using git version >= 2, you can make this the default via:

    git config --global commit.gpgsign true

Unfortunately `gpg2` still reports an error unless `sudo` is used:

    gpg2 --card-status
    gpg: selecting openpgp failed: Unsupported certificate
    gpg: OpenPGP card not available: Unsupported certificate

Hope to figure out the issue soon.


#### Web Of Trust

Signing another person's key:

1. Import your current Secret key to the air-gapped machine (if necessary).
2. Import the key to be signed (I simply bring over the entire public keyring).
3. Sign the person's public key.
4. `export` the signed key for them.
5. Transport that signed key file back to the online system.
6. `import` and email the key to owner. Encrypt the file / email to be sure that they have the means to decrypt with the key you signed.

#### Useful commands
    gpg --list-sigs --list-options show-keyserver-urls
    gpg -k --fingerprint --keyid-format long


## GPG Configuration file

* [Example config](../master/gpg.conf) file (`~/.gnupg/gpg.conf`):


# GUI Tools to make Open PGP more usable

#### Mac
* Use Apple's built-in `Mail.app` program with `GPGMail` (part of the fantastic [GPG Suite](https://gpgtools.org/)).
* Can be [setup to use a Gmail account via IMAP](https://support.google.com/mail/answer/78892?hl=en).

#### Android
* Use [K9 Mail](https://k9mail.github.io/) and [Open Keychain](https://www.openkeychain.org/) -- [Here is a tutorial](https://www.openkeychain.org/howto/#/).

#### Linux or Windows
* [Enigmail PGP plugin](https://enigmail.net/index.php/en/)
* Sync Google contacts with [gcontactsync](https://addons.mozilla.org/en-US/thunderbird/addon/gcontactsync/)

### License

WTFPL - See [LICENSE](https://github.com/jonathancross/jc-docs/blob/master/LICENSE) for more info.
