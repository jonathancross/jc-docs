A collection of SHA-256 software hashes I have verified
=======================================================

`a5146a143c7bbd6a0b8384a1aa233243b72cca94cbec62aa3d70a82f5b262550`  androidfiletransfer.dmg (v 1.0.50.2266)
`18317ba924475223ae6fc50787850e63ed078d4d4a2e8d534c5843a2df2a9bf2`  electrum-2.7.18.dmg
`6f2308b082e6b74ac43e31d59b3ea50555de02984fb6ba5a229bbeddb57e8025`  GnuPG-2.1.9.dmg
`0ec0f4bb66ef660d3c3b0433dd3186e093a1b4f23bf8fac8b4ebca9fa6d80420`  GPG_Suite-2015.09.dmg
`d8b618878b1949496197e31ee4b8d36b50ad6169cc5acef8c1cb1917e6b4200b`  hpprinterdriver3.1.dmg
`44271fef18fd07a29241e5324be407fa8edce77fb0b55c5646cd238092cdf823`  KeePassX-2.0.3.dmg
`d5e85933e74e5ba6a73f67346bc2e765075d26949c831a428166c92772f67dbc`  [md5deep-4.4.zip](https://github.com/jessek/hashdeep/releases/download/v4.4/md5deep-4.4.zip)
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


Explanation
===========

### How is this information useful?

If you trust me ([Jonathan Cross](https://github.com/jonathancross)), you can use the hashes above to check if the file you downloaded matches the one I downloaded.

### How do I know you created this file?

All changes to this file should be signed with my gpg key: [C0C076132FFA7695](https://jonathancross.com/2FFA7695.asc)

GitHub will show you that it is "Verified" with the subkey `D8578DF8EA7CCF1B`.

### How can I get the SHA-256 digest of a file on my computer?

One of these commands should work on all recent **Mac OSX / Linux** machines:

    openssl dgst -sha256 [filename]
    sha256sum [filename]

**Solaris:**

    digest -a sha256 [filename]

**Windows:**
You'll have to install software that can calculate hashes.  [hashdeep](https://github.com/jessek/hashdeep/releases) seems okay and is part of the md5deep-4.4.zip package above.

### What about PGP signatures?

I'll try add info about the signatures and keys I know of at some point.
