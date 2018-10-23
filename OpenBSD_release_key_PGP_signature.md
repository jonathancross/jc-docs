# OpenBSD release key PGP signature

**ISSUE:** Open BSD releases are not signed using PGP keys. Instead the project uses a [custom built tool called signify](https://www.openbsd.org/papers/bsdcan-signify.html) to sign releases.  The key used to sign is [available on the project website](https://www.openbsd.org/64.html) and used to be printed on official install CDs (which are no longer created).  This however requires you to trust the website creator, their hosting provider, certificate authorities, your browser and many others entities.

**Do the project maintainers publish a PGP signed message indicating the correct key?**

No.

**Can the PGP web of trust be used to verify the key somehow?**

I have not found a way to verify the signing key except by meeting a developer or maintainer in person.  So I did that on 2018-10-23.  The message below was signed by Theo Bühler `<tb@openbsd.org>` (PGP: `0x582F9C0EAA32139A`) and verified visually letter by letter by Reyk Flöter `<reyk@openbsd.org>` (PGP: `0x1A12678032292F9D`).

```
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

untrusted comment: openbsd 6.4 base public key
RWQq6XmS4eDAcQW4KsT5Ka0KwTQp2JMOP9V/DR4HTVOL5Bc0D7LeuPwA
-----BEGIN PGP SIGNATURE-----

iQIcBAEBAgAGBQJbz1fyAAoJEFgvnA6qMhOa2moQANMBA03ZYnOEhdiA613wEZIb
lV4/YE7Ma8PMtn0NFQe86a2Dj0Gwxo8qkXQjuWX+SA3y5Tnv7NBnHED44vNmAwDM
Nu+bzkLF5HbsVe+Rn1vwR6XqvcGblB3NVPEmpS+b/aG5uAV65AeEuxNFljCuP5LL
UH4QDg4nbFuZ8on0zt0oo3KALuxk6EGK7eNbef7BehWTc67MBQVxCPsoR5ZKRm5J
poUwLkXVSrEr2hD72hwG8D0CnHPnYwTQFsM52QlEeSFEhETN1dB/PMnIrxuMZSIh
6O8qz8x11yJdOxbQbxe+4PMST6PUURM6J3ZSawpPgFtxh/UUN8uMSZyOrZLOXWD8
C8CxIgje2KmwrbRWcPJ+KKOJJ+XMIeipwmCQj38zk1k1rzWdt+zTj3gxzpApXUlr
4Uz4IgnxdDuzMNdClspJ4tb6/kAnpvMQQ4svL5jG27+NcOIQONH2fZhD0eSX8WHF
8ktp0Yrw6+OfKgyG7936aobstH33RxJv5sCRvTNge4ny33I5zSJniinQFH+f9bNJ
3bhRnIZ+dCixIWDIIeq86CMI35hfafa6rVeEEynyUr+35TvW4AKWddfc5r/eqMkI
s69AuXIjeeIAZxfNHPUAsp9uVxH98MXPrgQG9Lr2fwQek7JRvHLDUEbuVjR5qLcL
0X/8/SxTaKnxk6bJaYK6
=eiQF
-----END PGP SIGNATURE-----
```

**How can I verify that the OpenPGP key used above (0x582F9C0EAA32139A) is legit?**

I (Jonathan Cross) have verified it in person, including checking a government-issued ID and we have exchanged key signatures.  My key (`0xC0C076132FFA7695`) is part of the PGP web-of-trust "Strong Set", therefore you should be able to [find a trust path](https://pgp.cs.uu.nl/) to it once your key is in the Strong Set.

This git commit was signed with my PGP key so I also certify the information you are reading.

**What about future releases?**

Once you have verified one key, you can install OpenBSD which contains keys used in the following release. In this way the verification process for all releases going forward can be bootstrapped from a single verified key like that one above.
