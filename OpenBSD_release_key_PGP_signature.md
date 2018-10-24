# OpenBSD release key PGP signature

**ISSUE:** Open BSD releases are not signed using PGP keys. Instead the project uses a [custom built tool called signify](https://www.openbsd.org/papers/bsdcan-signify.html) to sign releases.  The key used to sign is [available on the project website](https://www.openbsd.org/64.html) and used to be printed on official install CDs (which are no longer created).  This however requires you to trust the website creator, their hosting provider, certificate authorities, your browser and many others entities.

**Do the project maintainers publish a PGP signed message indicating the correct key?**

No.

**Can the PGP web of trust be used to verify the key somehow?**

I have not found a way to verify the signing key except by meeting a developer or maintainer in person.  So I did that on 2018-10-23.  The message below was signed by Theo Bühler `<tb@openbsd.org>` (PGP: `0x582F9C0EAA32139A`) and the key you see was also verified visually letter by letter by Reyk Flöter `<reyk@openbsd.org>` (PGP: `0x1A12678032292F9D`).

```
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA256

untrusted comment: openbsd 6.4 base public key
RWQq6XmS4eDAcQW4KsT5Ka0KwTQp2JMOP9V/DR4HTVOL5Bc0D7LeuPwA
-----BEGIN PGP SIGNATURE-----

iQIcBAEBCAAGBQJb0IKaAAoJEFgvnA6qMhOan0sP/1WR5fozYWbwHVQDSHKXP5yD
jjDjhW5T2jAFC4MWXJybdmGTkxEz1wYC9k0aen0hzWTz3M/e1Chcb0aVVql4MAjf
mTECSbr3493jXiYBWmhZC7Qce7nmgdR1KmAcvI3jffBetwrDpaUow9TuXy7U2JB2
zJQI0kT1oKNxg911s1R02uNcW5/Wrvx7UoIhqmn0DLvB+u81Y0JOC2R0JMRxVtqi
sX2g3HaZGwgDoPkfT+KeGQXG2OTwzRG2XFEpuX/2qc05z3MG24GnddwX66WlCGb1
o31qUjviPOBJsq6VGSRycGTalsz+1yPCQ5O3s4WRKebAAoG/nozSdQq2h3Pfgkle
ynsPX5yDS5tYbJERhyVBet4qDM+JXse6FXRl3LxOSkEKfi5Ved6LSf6/WbOXCTxO
R3OQqgp0FO30Tp+mRI0qSoYKQswUOox2TGCKlqWnZurNcEnJ64Zzo7hRtDj16vXa
7XUGo1FOfEfQb5RoHHmj6jfAenhOORb5iMyWi/9MQdb6k/Bj7srS3mKEllZoqLzH
4iFq7XaERNnCGQNUDPusmkqPDOsrl4oec82kCBHxFzYfSkwIZgFn5YBgtuj8vG+5
tmLcYQYH3O4ob0GaOws8Jg+CjUvNJGowWyOnxoqzZxpQRldT8yPdd4qyrYtZdsZz
UTghTbNqVsg6QzN9Xr2z
=irX3
-----END PGP SIGNATURE-----
```

**How can I verify that the OpenPGP key used above (0x582F9C0EAA32139A) is legit?**

I (Jonathan Cross) have verified it in person, including checking a government-issued ID and we have exchanged key signatures.  My key (`0xC0C076132FFA7695`) is part of the PGP web-of-trust "Strong Set", therefore you should be able to [find a trust path](https://pgp.cs.uu.nl/) to it once your key is in the Strong Set.

This git commit was signed with my PGP key so I also certify the information you are reading.

**What about future releases?**

Once you have verified one key, you can install OpenBSD which contains keys used in the following release. In this way the verification process for all releases going forward can be bootstrapped from a single verified key like that one above.

### Disclaimer

This document comes with no guarantees, do your own homework. [Feedback](https://github.com/jonathancross/jc-docs/issues/new?title=Feedback:%20OpenBSD%20release%20key) is welcome.

### License

WTFPL - See [LICENSE](LICENSE) for more info.
