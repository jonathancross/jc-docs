Secure PGP keys and Yubikey NEO
===============================

**Goal:** Create a secure OpenPGP keypair, eg: offline master key with subkeys stored on a Yubikey NEO hardware device.

Tutorials:
* https://www.esev.com/blog/post/2015-01-pgp-ssh-key-on-yubikey-neo/
* http://blog.josefsson.org/2014/06/23/offline-gnupg-master-key-and-subkeys-on-yubikey-neo-smartcard/
* https://developers.yubico.com/PGP/Importing_keys.html
* [Why Subkeys do not have a Public key](http://security.stackexchange.com/questions/84132/gpg-detaching-public-subkeys-why-cant-i-do-it)
* [Why do I see “Secret key is available.” in gpg when it is not?](http://security.stackexchange.com/questions/115230/why-do-i-see-secret-key-is-available-in-gpg-when-it-is-not)
* [Yubico developer signing keys](https://developers.yubico.com/Software_Projects/Software_Signing.html).
* [Using an OpenPGP SmartCard](http://www.narf.ssji.net/~shtrom/wiki/tips/openpgpsmartcard) (some good troubleshooting info)
 
#### Security concerns
* Yubikey NEO issued before 2015-04-14 [contain an insecure OpenPGP applet](https://developers.yubico.com/ykneo-openpgp/SecurityAdvisory%202015-04-14.html).

#### Things that confused me
*  *Primary Key* = "Master Key"
*  `--armor` = This option causes the key to be output as ASCII (instead of the default binary format).  Why not use `--ascii`?
*  By default, `gpg -k` will **not** list fingerprints or the recomended longer key ID format experts agree should be used.  Instead, it lists the [unsafe 8-character "short" format](http://www.asheesh.org/note/debian/short-key-ids-are-bad-news.html).  Why is the default the less secure option?  Use `gpg -k --fingerprint --keyid-format long` instead.
* When you use `gpg --search-keys KEYID`, the command will often not find perfectly valid keys (eg: those on pool.sks-keyservers.net or pgp.mit.edu).  There is a bunch of keyservers, so the key you are looking for *may* be on any of them, or *none of them*, or maybe it is there, but the search algo doesn't find it.
* If you add a picture (must be a jpg!), add a default keyserver, etc. it will be stored as part of your Public key.  So that will be changing often and needs to be republished each time.  It is still not clear to me which actions change your Public key:
  * `YES` Adding a jpg photo.
  * `YES` Adding / revoking an identity. (NOTE: identities cannot *modified*)
  * `YES` Updating the expiration date.
  * `YES` Certifying / adding or revoking a subkey.
  * `YES` Importing a signed copy of your key from someone else.
  * `YES` Adding a keyserver url.
  * `???` Changing the password used to encrypt the master key (I don't think so)?
  * `NO` Signing another person's key.
  * `NO` Publishing your Public key to a keyserver.

#### gpg will use various cryptic symbols noting the properties of the key.
When listing Secret keys (`gpg --list-secret-keys` or `gpg -K`) you may see:
* `sec` = Secret (aka Private) and Public key exists for the Master key. 
* `sec#` = Master key secret is not present, only the Public key (called a "stub").  This is normal when using subkeys on the online system. 
* `uid` = User ID.  Combination of name, email address and an optional comment.  You can have multiple UIDs, add and remove (`revoke`) them without breaking your Master key.  If you add a photo, it will be a new `uid` added ot the key.
* `ssb` = Subkey Certified by the master key.
* `ssb>` = Subkey where the private portion is on the Yubikey or another device.

When listing Public keys (`gpg --list-keys` or `gog -k`) you may see:
* `pub` = Public portion of your Master keypair.
* `sub` = Subkey (you will never actually work with a public key for a Subkey, only the Master).

When editing a key (`gpg --edit-key KEYID`) you may see:
* `sub*` = The star indicated athe the particular Subkey is selected for editing.
* `sig!3` = You see this after running the `check` command. I don't know what it means.

There are different types of keys, you can see this on the right as "usage":
* `usage: C` = **Certify** other keys, IE: this is your Master key.
* `usage: S` = **Sign** messages so people know it was sent from you.  This can be a Subkey. 
* `usage: E` = **Encrypt** messages to sent to other people.  This can be a Subkey.
* `usage: A` = **Authenticate** yourself, for example when using SSH to log into a server.  This can be a Subkey.

#### Difficulties with offline master key

* There is no existing linux distribution that can write the keys to the Yubikey as-is.  Therefore you will need to try and transfer all required software to the offline system (complex and could compromise your offline system), or you sacrifice some security and temporarily bring the subkeys onto a system which can easily write to the Yubikey.
  * In my case, I tried to get the device to work using offline Xubuntu, Tails, etc, but was not successful.
  * Instead, I created the master key, then put that into a TrueCrypt container.  Then did the same with a separate container for subkeys.  I then moved the subkey container to a computer with internet connection turned off, opened it and wrote the subkeys onto the Yubikey device.  I believe the computer was free of malware, but annot be certain.  The master key is only used on an air-gapped computer, so it is safe and can be used to revoke subkeys if needed.

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

Can then use `git commit -a -S` (although I don't know why `-S` is needed when signing is configured globally)

Unfortunatly `gpg2` still reports an error unless `sudo` is used:

    gpg2 --card-status
    gpg: selecting openpgp failed: Unsupported certificate
    gpg: OpenPGP card not available: Unsupported certificate

Hope to figure out the issue soon.


#### Web Of Trust

Signing another person's key:

1. Import your current Secret key to the air-gapped machine
2. Sign the person's public key
3. `export` the signed key for them
4. Transport that signed key file back to the online system
5. `import` and republish / email to the friend.  Can encrypt the file before sending to be sure that they have the means to decrypt with the key you signed.

TODO: Confirm if my Public key must also be imported / re-exported.


#### Useful commands
    gpg  --list-sigs --list-options show-keyserver-urls
    gpg -k --fingerprint --keyid-format long


## Configuration file

* [Example config](../master/gpg.conf) file (`~/.gnupg/gpg.conf`): 

### Thunderbird
* [Enigmail PGP plugin](https://enigmail.net/index.php/en/)
* Sync Google contacts with [gcontactsync](https://addons.mozilla.org/en-US/thunderbird/addon/gcontactsync/)
