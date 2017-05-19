A collection of SHA-256 software hashes I have verified
=======================================================

## Mac OSX

`a5146a143c7bbd6a0b8384a1aa233243b72cca94cbec62aa3d70a82f5b262550`  androidfiletransfer.dmg (v 1.0.50.2266)
`18317ba924475223ae6fc50787850e63ed078d4d4a2e8d534c5843a2df2a9bf2`  electrum-2.7.18.dmg
`6f2308b082e6b74ac43e31d59b3ea50555de02984fb6ba5a229bbeddb57e8025`  GnuPG-2.1.9.dmg
`0ec0f4bb66ef660d3c3b0433dd3186e093a1b4f23bf8fac8b4ebca9fa6d80420`  GPG_Suite-2015.09.dmg
`d8b618878b1949496197e31ee4b8d36b50ad6169cc5acef8c1cb1917e6b4200b`  hpprinterdriver3.1.dmg
`44271fef18fd07a29241e5324be407fa8edce77fb0b55c5646cd238092cdf823`  KeePassX-2.0.3.dmg
`0d6d03b6d5b13e0916f18d156dd83a5b46d9f6b25625af8723f211ad39d261cb`  Keybase.dmg (92012764 bytes) v1.0.22-20170515141716+b608f0e ([Downloaded](https://keybase.io/docs/the_app/install_macos) on 2017-05-20)
`b46e5786343f236d203037a7ace8f1b28145a51a3f84fa527efcf62f47b5b8de`  meld-1.8.4.tar.xz
`db3572c5c6905b09f4fc28415a7f6f223014391492dd2165ed1bc8512ac4e6fd`  meld-3.12.3.tar.xz
`c80ca68037158216a080e59e90b0a70761cff2f317d3c9cd0eeb661e8e2a1f99`  monero-gui-mac-x64-v0.10.3.1.tar.bz2
`fd17d55a8c9e901ff4064c39d9e14786cdd077aff9b3bb556e60d3a5e322050c`  monero-mac-x64-v0.10.3.1.tar.bz2
`0f31b7d8f00779969e339bec89163b573c9c9e9ce10cdbbe0c4acfc11fcb527b`  Mumble-1.2.15.dmg
`59a2549913f523dac5a51859de135d92e434c1801ca571eb2d74664d19d6b627`  picasamac39.dmg
`dda519484075ce455f91962d04ca57535c50604b30e886e5025ab97a4e5be1df`  qbittorrent-3.3.11.dmg
`fe46c69d783f2aa290d18caec30b3f17481c47def9c271dc66db1b7bbd3074c5`  [sudo-1.8.19p2.pkg](https://www.sudo.ws/sudo/dist/packages/macOS/10.11/sudo-1.8.19p2.pkg)
`04db58b737c05bb6b0b83f1cb37a29edec844b59ff223b9e213ee1f4e287f586`  TrueCrypt 7.1a Mac OS X.dmg
`de47cbbbcd9be8241a31a7924a6840a70215300154d352f28c31d8fbb2edbf2e`  tuxerantfs_2015.dmg
`c9b3a373b7fd989331117acb9696fffd6b9ee1a08ba838b02ed751b184005211`  XQuartz-2.7.7.dmg

## LINUX

`4915473265d58720fd8f019e536c2b7fb02648ab51a8087e84aa1e2434788452`  monero-gui-linux-x64-v0.10.3.1.tar.bz2
`f3f31634c05243e33a82a96e82c3cd691958057489e47eebe8ac3b0c0e6dd3b4`  sublime-text_build-3126_amd64.deb


Explanation
===========

### How is this information useful?

You can use the hashes (aka "digest" values) above to check if a file you downloaded matches the one I ([Jonathan Cross](https://github.com/jonathancross)) downloaded.  If you find a mismatch, **[please let me know](https://github.com/jonathancross/jc-docs/issues/new?title=Feedback:%20Software_Hashes)** immediately.

### How does this list provide security?

[SHA-256](https://en.wikipedia.org/wiki/SHA-2) (Secure Hashing Algorithm, 256 bits in length) can create a unique string of number and letters for any piece of data.  This allows you to confirm that the file you downloaded is the same as the one created by the developer.  Sometimes, it is difficult to determine what the *correct* hash should be because there is no definitive answer from the developer, this is one situation in which the list above might be most useful.  Or maybe you trust me and therefore want to ensure that you install the exact same version I did.  Or maybe it is just a way for me to record a log of what I have verified / installed and is of no use to anyone  :-)

### How do I know YOU created this file?

All changes (git commits) to this file are signed with my GPG/PGP key: [C0C076132FFA7695](https://jonathancross.com/2FFA7695.asc)

Here in GitHub, each commit will have a green "Verified" badge for the GPG subkey `D8578DF8EA7CCF1B`. You can also verify independently via `git show --show-signature HEAD` if you don't trust GitHub.

### How can I get the SHA-256 digest of a file on my computer?

One of these commands should work on all recent **Mac OSX / Linux** machines:

    openssl dgst -sha256 [filename]
    sha256sum [filename]

**Solaris:**

    digest -a sha256 [filename]

**Windows:**

You'll have to install software that can calculate SHA-256 hashes.  [hashdeep](https://github.com/jessek/hashdeep/releases) (part of the `md5deep-4.4.zip` package) seems okay.


### What about PGP signatures?

I'll try add info about the signatures and keys I know of at some point.
