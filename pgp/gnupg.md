Info about GNU Privacy Guard and OpenPGP - [gpg.wtf](https://gpg.wtf)
=======================================

GNU Privacy Guard is very powerful software with a terrible interface implementing a confusing protocol with a lot of cruft.

This document is not a "how to" guide, but rather a collection of notes -- `CTRL-F` is your friend. This site will hopefully answer questions and explain the mysteries of gpg and PGP so that you too can take advantage of these tools and improve your security / privacy.

This page assumes you have basic familiarity with `gpg` and have already created an OpenPGP key. If not, please see [Secure PGP keys and Yubikey NEO.md](https://github.com/jonathancross/jc-docs/blob/master/pgp/Secure%20PGP%20keys%20and%20Yubikey%20NEO.md) for information on how to create an offline master key and then transfer the sub keys onto a YubiKey [hardware device](#hardware) for daily use.

### Getting started

* [Example config file](https://raw.githubusercontent.com/jonathancross/jc-docs/master/pgp/gpg.conf) (`~/.gnupg/gpg.conf`) - Some better defaults.
* [My key signing policy](https://jonathancross.com/C0C076132FFA7695.policy.txt) - to learn about different signature types and what they mean to me.

### Hardware

Recommended hardware devices to manage your OpenPGP keys:

* [OnlyKey](https://onlykey.io/) Open Source hardware, ability to clone / backup device, firmware updates, hardware PIN keypad and many [many nerdy features](https://docs.onlykey.io/features.html)!
* [NitroKey](https://www.nitrokey.com/products/nitrokeys) Also a great option now with the most important features matching or exceeding the YubiKey.
* [YubiKey](https://www.yubico.com/products/) The classic hardware token which _used_ to run Open Source apps, but, sadly [does not anymore](https://github.com/Yubico/ykneo-openpgp/issues/2#issuecomment-218436213).

# Web Of Trust

<img align="center" src="https://imgs.xkcd.com/comics/responsible_behavior.png" alt="xkcd : web of trust + responsible behavior"><br>[xkcd.com](https://xkcd.com)

The [OpenPGP Web Of Trust](https://en.wikipedia.org/wiki/Web_of_trust) is a way to establish the authenticity of the binding between a public key and its owner without relying on centralized authorities. Participants can chose to verify, then sign each other's keys, then publish those signatures for other people to use.  Once your key is in the "Strong Set" (set of cross-signed keys), anyone can use a tool such as [the PGP pathfinder](https://the.earth.li/~noodles/pathfind.html) to easily calculate _trust paths_ from one key to another (modern software will do this automatically).  This can be especially helpful when verifying digital signatures on software for example.

"Signing" someone's key means that you use your Master key's `C` (Certify) capability to make a digital signature on one or more ID's of their public key.  This indicates to what degree you verified the data in that specific UID (usually name and email address).  Ideally the checking should be done in-person, government issued ID should be compared to the name listed in the key UID, and the key fingerprint should be provided by the owner on paper to be taken home and verified + signed later.

Here are [slides from a presentation I did on the OpenPGP Web Of Trust](https://docs.google.com/presentation/d/1bGSWwbFheaxgs35gh3wAOzR1g1Us8U-_Ix_Om1KAXWI/edit) with visual examples.

### The Web Of Trust is slowly dying...

In recent years, much of the infrastructure which made the Web Of Trust usable has been dismantled / neglected.  I consider this a huge loss as we still don't have equivalent tools in many cases.

1. Most keyservers now silently strip out 3rd party certifications.  Due to the design of OpenPGP keys, 3rd party signatures can be embedded into anyone's key.  This unfortunately means that [an attacker can DOS attack someone by stuffing bogus signatures into a key](https://gist.github.com/rjhansen/67ab921ffb4084c865b3618d6955275f#mitigations) and make it too big to effectively use. Most gpg implementations have quietly switched to a specific keyserver based on [Hagrid](https://gitlab.com/hagrid-keyserver/hagrid) which **strips all 3rd party certs** from keys it touches:
   - `hkps://keys.openpgp.org`
Very few people understand that this will make the OpenPGP WOT basically unusable as none of the connection data will be visible.
   - Solution: Use keyserver.ubuntu.com instead, or send/receive keys directly with others.
   - NOTE: *uploading* keys does not expose you to the above mentioned attack vector.

2. Once you have the certifications you need to verify keys, you can use a tool such as [wotmate](https://www.kali.org/tools/wotmate/) locally as a "pathfinder" between keys.  Basically searching for trust relationships between your key, the ones you have verified and hopefully ones which were verified by people you trust to do a good job.

3. The original PGP Pathfinder website is dead, but there is a mirror here as of 2025: [https://the.earth.li/~noodles/pathfind.html](https://the.earth.li/~noodles/pathfind.html) -- you can use this to discover trust paths in the OpenPGP Web Of Trust.

4. Even GnuPG itself will silently strip out 3rd party signatures (certs) in many cases.  This is a moving target, so I'll try to update this doc with info as I discover issues / workarounds.

### Signing keys offline

Signing another person's key with your "offline" master key is far more secure than keeping the master key on a normal Internet-connected computer.  It is also a bit more complex, but instructions below should easily guide you through the process.  Replace `KEYID` below with the actual long ID of the key you want to sign:

1. Locate the key you want to sign, eg: `gpg --search KEYID`.  Then type the number of the key you want to import into GnuPG's database.
2. Check the master key fingerprint, eg: `gpg --fingerprint KEYID`
3. When satisfied, export the public key to a file, eg: `gpg -a --export KEYID > KEYID_unsigned.asc`
4. Put the key you want to sign onto a clean USB stick (or find some other way to get it into your air-gapped computer).
5. Enter your air-gapped environment (eg, boot into TailsOS).
6. Import your current **Secret key** (aka Master key) to the air-gapped machine.
7. Check your key is available with: `gpg -K` (big 'K') or `gpg --list-secret-keys`
8. Import the public key to be signed: `gpg --import KEYID_unsigned.asc`
9. Sign the person's public key: `gpg --ask-cert-level --sign-key KEYID`
   - You will be prompted to specify which IDs you want to sign and asked how thoroughly you checked the identity info.  Here is a copy of [my key signing policy](https://jonathancross.com/C0C076132FFA7695.policy.txt) which might be helpful place to start.
   - I recommend signing all IDs here (default) and later deleting any signatures you don't want to send.
10. Export the signed key as a file: `gpg -a --export KEYID > KEYID_signed.asc`
11. Transport that signed key file back from the air-gapped machine to the online system.
12. Import the signed key: `gpg --import KEYID_signed.asc`
13. Verify your signature on their key: `gpg --check-sigs KEYID`
14. Finalize the verification process by emailing the signature to the owner (below).

#### Ensuring that your signature goes to the right UID

It is tempting to just upload the signed key directly to a keyserver, but this is considered bad form because the data you signed is not verified and uploading irrevocably publishes data that the user may not want to make public (see section below about what can be changed on a keyserver).

Instead, we will send each signed UID to the email address listed in an **encrypted email**.

This ensures that:
1. They still control that email address. (can read the email)
2. They control the private key for the public key you are signing. (can decrypt the message)

If there is only 1 email address listed in the key, then this is easy -- just send the `KEYID_signed.asc` file to the email address listed (encrypted email of course).  If there is more than one email address, then I recommend [exporting each email address UID separately](#exporting-a-specific-uid) into an asc file and then sending to the corresponding email address.

Some UID may not contain an email address, but rather a photo, website or other metadata.  Personally I leave those sigs intact for all email addresses or don't sign them at all if they cannot be verified.

## What is a keyserver?

A key server is a repository of keys.  Anyone can upload their own key there or another person's key and the key there could be manipulated by the owner of the server.  DO NOT BLINDLY TRUST THE KEYS.  You can use a keyserver as a convenient way to locate a key from a fingerprint, but always verify the key after downloading.

When sharing your key (uploading), I highly recommend using these keyservers based on the [Hockypuck](https://hockeypuck.io/) backend because they allow upload of signature data:
* `keyserver.ubuntu.com`
* `pgp.surf.nl`


One can use a keyserver to **search** for a key via the web by prefixing with `https://` or on the commandline with the prefix `hkps://` like this:

    gpg --keyserver hkps://keyserver.ubuntu.com --search 0xC0C076132FFA7695

You can also upload your key to a server:

    gpg --keyserver hkps://keyserver.ubuntu.com --send-key YOUR_KEY_ID

Feel free to use [this script](https://raw.githubusercontent.com/jonathancross/jc-docs/master/pgp/send-pgp-keys.sh) I made to automate the upload of your key to keyservers, your website and / or Keybase.io.

Generally speaking, you should not send other people's keys to keyservers unless you really know what you are doing.  Better to email to them and have them upload (if they choose).

#### Concerns about the Web of Trust

The OpenPGP Web Of Trust is not perfect.  Publishing keys and personal information on public servers may open you up to receiving more spam and analysis of your social graph via key signatures.  These are all concerns that might prevent someone from participating.  In my mind, the overall benefits outweigh the dangers, so I participate, but many do not agree and are waiting for better options.

#### More details about the OpenPGP trust model in gpg

When attempting to determine to what degree a key is "trusted", gpg will offer various pieces of information explaining how the trust level is being calculated.  Example:

```
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   4  signed: 115  trust: 0-, 0q, 0n, 0m, 0f, 4u
gpg: depth: 1  valid: 115  signed:  67  trust: 3-, 0q, 0n, 2m, 110f, 0u
gpg: depth: 2  valid:  50  signed:  39  trust: 35-, 2q, 1n, 5m, 7f, 0u
gpg: depth: 3  valid:   3  signed:   6  trust: 0-, 0q, 0n, 3m, 0f, 0u
gpg: next trustdb check due at 2025-07-09
```

Please see [this excellent explanation](https://security.stackexchange.com/a/41209/16036) from [Jens Erat](https://security.stackexchange.com/users/19837/jens-erat) of the values and meanings seen above.

#### PGP is dead

Many people have [declared PGP dead](https://blog.cryptographyengineering.com/2014/08/13/whats-matter-with-pgp/) because it is hard to use, doesn't protect metadata in encrypted emails and supports too much legacy crypto.  Although there are very good arguments against it, I still think it is undeniable that it works well for verifying digital signatures, has wide support (hardware, software and people) and does a decent job at encrypting email once you have a properly setup client.  The [Web Of Trust](#web-of-trust) has huge problems, but for those who take the effort to participate, it provides one of the few functioning examples of decentralized key verification.  Could this be done better? Absolutely!  But this is the best we have right now and attempts to replace it have always fallen short of the features needed.

## RANT: Random things that confused me about gpg

* Many options are not listed in the `--help` or man pages.  See [Esoteric Options](https://www.gnupg.org/documentation/manuals/gnupg/GPG-Esoteric-Options.html) for a few interesting ones.
* The term *Primary Key* = "Master Key"
* The term *subkey* refers to a key which is certified by the *Primary Key*
* `--armor` = This option causes the key to be output as ASCII (instead of the default binary format).  Why not use `--ascii`?  Furthermore, users will encounter plenty of nonsense if you forget this option while trying to encrypt a message.  ALL of these will fail without a useful error message for example:

        gpg --encrypt
        gpg --encrypt --recipient ja@wikileaks.org
        gpg --encrypt ja@wikileaks.org
        gpg --recipient 92318DBA
* [Why do I see “Secret key is available.” in gpg when it is not?](https://security.stackexchange.com/questions/115230/why-do-i-see-secret-key-is-available-in-gpg-when-it-is-not)
* The command `gpg --armor --export=2FFA7695` will export *ALL* public keys, not just `2FFA7695` as one might expect.  Unlike many other gnu programs, gpg doesn't support the `=` (equals sign) as value separator, so it just silently assumes you want everything.
*  By default, `gpg -k` will **not** list fingerprints or the recommended longer key ID format experts agree should be used.  Instead, it lists the [unsafe 8-character "short" format](https://www.asheesh.org/note/debian/short-key-ids-are-bad-news.html).  Why is the default the less secure option?  Use `gpg -k --fingerprint --keyid-format long` instead.
* When you use `gpg --search-keys KEYID`, the command will often not find perfectly valid keys.  There is a bunch of keyservers, so the key you are looking for *may* be on any of them, or *none of them*, or maybe it is there, but the search algo doesn't find it.
* If you add a picture (must be a jpg!), add a default keyserver, etc. it will be stored as part of your Public key.  Your pubkey will be changing often and should be republished each time.

#### Which actions change your pubkey?

In gpg, your "public key" is actually a collection of many pieces of metadata, user IDs, the master key and subkeys, signatures, notations and preferences.  After making changes, it was unclear to me which actions changed my public key file and would require it be uploaded to a keyserver.  Here is a list:
  * `YES` Adding a jpg photo.
  * `YES` Adding / revoking an identity. (NOTE: identities cannot be *modified*)
  * `YES` Changing the order of UIDs (identities).
  * `YES` Updating the expiration date on keys / resigning subkeys.
  * `YES` Certifying / adding or revoking a subkey.
  * `YES` Importing a key signature from someone else.
  * `YES` Adding a keyserver url.
  * `YES` Adding notation data.
  * `NO` Signing another person's key.
  * `NO` Publishing your Public key to a keyserver.

#### Can I make changes to a key on a keyserver?

There are 2 major different backends with very different models:

  * [Hagrid](https://gitlab.com/hagrid-keyserver/hagrid)-based keyservers (eg keys.openpgp.org) authenticate your email address and will let you make some changes to your key. But you cannot upload other people's key information there, even info they cryptographically signed.

  * [Hockypuck](https://hockeypuck.io/)-based server (eg keyserver.ubuntu.com) are the old-school servers which do not authenticate.  They are untrusted repositories of key material and nothing can be deleted, only added.
    You can add valid signatures or new, certified UIDs *to any key* (not just your own).
    You can also update expiration dates (ie _adding_ a signature with a later expiration date) for any key.

#### Many ways to represent a public key...

Examples representations of my key:

1. The full [pubkey file](https://jonathancross.com/C0C076132FFA7695.asc) is needed to verify signatures and can be represented as ASCII text or binary (default). (the file can be hundreds of kilobytes of data depending on the number of signatures).
2. You can have a "hash" of the key data (used to sync key updates between servers) - `AECC01E6C0C2C94792F124968F4FFA4A`.
3. Key "fingerprint" (160 bit sha1 hash, eg `gpg --fingerprint KEYID`), normally displayed with spaces. Example:<br>
   `9386 A2FB 2DA9 D0D3 1FAF  0818 C0C0 7613 2FFA 7695`
4. _"Long"_ (64 bit) key ID: `C0C076132FFA7695` (last 16 hex chars of the fingerprint, ie `--keyid-format long`) [1]
5. _"Short"_ (32 bit) key ID: `2FFA7695` (last 8 hex chars of the fingerprint. **INSECURE:** Do not rely on these) [1][2]

[1] _Long_ and _Short_ Key IDs can be prefixed with `0x` to indicate they are hex.<br>
[2] _Short_ Key IDs are deprecated as they are **[VERY EASY to brute-force](https://evil32.com/)**.

### Cryptic symbols and key properties

When listing Secret keys (`gpg --list-secret-keys` or `gpg -K`) you may see:
* `sec` = Secret (aka Private) and Public key exists for the Master key.
* `sec#` = Master key secret is not present, only a "stub" of the private key.  This is normal when using subkeys without their Master key being present.
* `uid` = User ID.  Combination of name, email address and an optional comment.  You can have multiple UIDs, add and remove (`revoke`) them without breaking your Master key.  If you add a photo, it will be a new `uid` added to the key. When people "sign your key", they are really signing one or more of these UIDs.
* `ssb` = Subkey Certified by the master key.
* `ssb>` = Subkey where the private portion is on a [hardware device](#hardware).

When listing Public keys (`gpg --list-keys` or `gpg -k`) you may see:
* `pub` = Public portion of your Master keypair.
* `sub` = Subkey (you will never actually work with a public key for a Subkey, only the Master).

When editing a key (`gpg --edit-key KEYID`) you may see:
* `sub*` = The star indicates the particular Subkey is selected for editing.
* `sig!3` = You see this after running the `check` command. The number explains the type of signature (see below).

When listing signatures (`gpg --list-sigs KEYID`) you may see:
* `sig `, `sig 1`, `sig 2`, `sig 3` = How thoroughly was the identity claim verified (`sig`=unknown ... `sig 3`=extremely thorough).
Here is [a detailed explanation](https://security.stackexchange.com/a/141508/16036).

There are different types of keys, you can see this on the right as "usage":
* `usage: C` = **Certify** other keys, IE: this is your Master key.
* `usage: S` = **Sign** messages so people know it was sent from you.  This can be a Subkey.
* `usage: E` = **Encrypt** messages to other people.  This can be a Subkey.
* `usage: A` = **Authenticate** yourself, for example when using SSH to log into a server.  This can be a Subkey.

## A few useful examples

#### Work with a fresh, empty keyring

This command will cause a new, temporary keyring to be created.  This can be helpful for checking a key / signature before importing it into your real keyring, or used for experiments, etc.

```
export GNUPGHOME=$(mktemp -d /tmp/.gnupgXXXXXX)
```

#### Multiple private keys

The _local user_ option allows you specify the key used for signing if you have multiple private keys.

````
gpg --sign-key 0xBAADABBA --local-user 0xDEADBEEF
````

#### Re-signing a key

In some circumstances you may want to re-sign a certain UID, eg using a stronger hash function like SHA512, adding a notation or a new expiration date.  In most cases, you will need to add the `--expert` option in order to force gpg to sign the UID again.

````
gpg --ask-cert-level --expert --sign-key 0xBAADABBA
````

#### Exporting a specific UID

Public keys can contain a variety of UID assertions such as email address, name, photos, websites and arbitrary text.
Sometimes you might want to only export a particular UID (eg when signing UIDs for a keysigning party and want to email each signed UID to the corresponding email address).  You can use a complex set of [filter expressions](https://www.gnupg.org/documentation/manuals/gnupg/GPG-Examples.html) to achieve this.  Here is an example:

```
gpg -q --armor --export \
    --export-filter keep-uid="uid = Jonathan Cross <jcross@gmail.com>" \
       0xC0C076132FFA7695 > just_his_email.asc
```

More complex examples can be made using substring match `keep-uid="uid =~ Alfa"`, `&&` or `||` logical connection operators, etc.

#### Encrypting a message on the commandline without signing

This does not require a private key at all, just the pubkey for 0xBAADABBA.

```
gpg -aer 0xBAADABBA
[type your message here]
```
Type `^d` (Control-d) to end the message and have gpg display the encrypted text.

## Using gnupg offline

The recommended way to use gpg in a secure manner is to keep the master key offline and only use it on an air-gapped computer. Booting into [Tails OS](https://tails.boum.org/) is a convenient way to work with this kind of sensitive material as it will "forget" anything you do on the system as soon as it is restarted.  Installing Tails on a USB stick works well on my MacBook Air as there is no functioning WiFi driver and furthermore it is easy to disable networking from the welcome screen.  Tails now contains a modern version of Gnupg 2.1+ which fixes many known bugs in previous versions.

For everyday use, it is recommended to separate the primary (master) key from encryption, signing, and / or authentication subkeys and keep those subkeys on a hardware device (see below) while keeping the primary key offline.  This allows you to use gpg easily, while ensuring that if the hardware device is lost / compromised, you can always revoke the subkeys and issue new ones without losing certification signatures on your key.

## Hardware devices

Securing your keys using a hardware device that is independent from your computer is highly recommended.  This will drastically reduce the attack surface and help ensure that you are in control of the keys.  Here is [a spreadsheet](https://docs.google.com/spreadsheets/d/1zbuGucuAmum1UuUw1cozMNVz1VfKTLdSYlCv-6AEYyk/edit#gid=0) which compares the various properties of different hardware devices.

### Creating stubs on a new computer

When you are on a new computer and want to use a [hardware device](#hardware), you will need to create on-disk "stubs" of the keys that reside on your hardware device.

1. On Linux, you might need to add [these udev rules](https://github.com/Yubico/libu2f-host/blob/master/70-u2f.rules) to `/etc/udev/rules.d/`.
2. Run `sudo gpg --card-edit`
3. Get your key stubs: `fetch`
4. Quit: `q`
5. May need to change the keyring owner to yourself if it was just created with sudo above:

        sudo chown -R $USER ~/.gnupg/*
6. Check your work by running `gpg --list-secret-keys`.  If you see `ssb>` for the subkeys, then all is good.


# Using OpenPGP with git

### Configure git to sign all commits with an OpenPGP key
```bash
git config --global user.email [EMAIL ADDRESS OF YOUR PGP IDENTITY]
git config --global user.signingkey [YOUR KEY HERE]
git config --global commit.gpgsign true  # Only works in git >= 2
```

You should also [add your OpenPGP public key to GitHub](https://github.com/settings/keys) so that verification info is displayed to users.

NOTE: Both `git` and GitHub will show that code was signed with your signing **subkey** (rather than primary key).  This may be confusing for users because normally the primary key is used / publicly shared by devs and subkeys are selected quietly in the background as needed.  See [example here](https://github.com/jonathancross/j-renamer/commit/e93093aa5d87a33b0758b1614c31d70aae7999ed) and click on the green "Verified" button.

### Show commit signature info ([more info](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work))
```bash
git log --show-signature -1               # Details of last commit sig.
git log --pretty="format:%h %G? %aN  %s"  # Log of last commits. The "G" means good signature, "N" means no sig.
```

### Linux git commit signing

I can then use `git commit -a -S` to sign my commit. You can make this the default via:

    git config --global commit.gpgsign true

Unfortunately `gpg2` still reports an error unless `sudo` is used:

    gpg2 --card-status
    gpg: selecting openpgp failed: Unsupported certificate
    gpg: OpenPGP card not available: Unsupported certificate

### Configure git to authenticate via SSH with an OpenPGP key

> will work for Linux and Windows
> in Windows use git-bash, bundled with git installation

- add auth subkey in GnuPG
- get auth subkey id `AUTH_SSB_ID`
- add auth subkey KEYGRIP to known ssh identities
```bash
echo AUTH_SSB_KEYGRIP >> ~/.gnupg/sshcontrol
```
- add ssh representation of auth subkey to *SSH keys* in VCS userprofile settings
```bash
gpg --export-ssh-key AUTH_SSB_ID!
```
- configure ssh connection
  - enable ssh ability of gpg-agent
```bash
echo enable-ssh-support >> $HOME/.gnupg/gpg-agent.conf
```
  - replace ssh-agent with gpg-agent - add following to bash initialization file
```text
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpg-connect-agent /bye
```


## Additional tools / scripts / documentation

* [paperkey](https://github.com/dmshaw/paperkey/) Backup / restore your gpg keys on paper.
* [signing-party](https://salsa.debian.org/signing-party-team/signing-party) A fantastic collection of tools for use in key signing parties, WOT analysis, etc for *nix

I have written a few scripts to help with various PGP / GPG related tasks:

* [Secure PGP keys and Yubikey NEO](https://github.com/jonathancross/jc-docs/blob/master/pgp/Secure%20PGP%20keys%20and%20Yubikey%20NEO.md) - Notes on GPG and YubiKey NEO setup.
* [gpg.conf](https://github.com/jonathancross/jc-docs/blob/master/pgp/gpg.conf) - Example "hardened" configuration file for GnuPG with secure defaults.  Much of this is no longer needed because Gnupg now has sane defaults.
* [gpg-agent.conf](https://github.com/jonathancross/jc-docs/blob/master/pgp/gpg-agent.conf) - gpg-agent configuration for ssh authentication via OpenPGP key.
* [gpg-keys-signed-by.pl](https://github.com/jonathancross/jc-docs/blob/master/pgp/gpg-keys-signed-by.pl) - Search for PGP keys in your local keychain signed by a given key.
* [send-pgp-keys.sh](https://github.com/jonathancross/jc-docs/blob/master/pgp/send-pgp-keys.sh) - Upload your GPG public key to multiple services after a change.  Supports [keybase](https://keybase.io), public keyservers and / or your own web server.
* [search-pgp-wot](https://github.com/jonathancross/jc-docs/blob/master/pgp/search-pgp-wot) - Check all signatures on a given PGP key looking for any in the Web Of Trust "Strong Set". [broken until I update to use a new pathfinder]
* [email-key-uids.sh](https://github.com/jonathancross/jc-docs/blob/master/pgp/email-key-uids.sh) - MacOS: Split a signed OpenPGP key into component UIDs and email each to the owner via Apple's Mail.app.
* [OpenBSD release key PGP signature](https://github.com/jonathancross/jc-docs/blob/master/pgp/OpenBSD_release_key_PGP_signature.md) - How to verify the OpenBSD 6.4 release signing key using OpenPGP web of trust.


# Additional Software

* See https://www.openpgp.org/software/
* [wotmate](https://www.kali.org/tools/wotmate/)

## Disclaimer

This document comes with no guarantees, do your own homework. [Feedback](https://github.com/jonathancross/jc-docs/issues/new?title=Feedback:%20Gnupg%20WTF) is welcome.

## License

WTFPL - See [LICENSE](https://github.com/jonathancross/jc-docs/blob/master/LICENSE) for more info.
