# Does Homebrew check OpenPGP signatures of packages?

TL;DR; No.

### How does brew verify packages

Homebrew uses SHA-256 hash of the package to verify integrity, but not authenticity.
Example: [homebrew-cask/gpg-suite.rb](https://github.com/Homebrew/homebrew-cask/blob/6ec7d441cd810a588a1ba24f4d77da636c987928/Casks/gpg-suite.rb#L3) has the following SHA-256 hash: `e0166931d58427bbd9cc0988765b4f723c554fa19e14d7697e152468c7e04f0d`

### Are OpenPGP signatures checked when available?

OpenPGP signatures are not checked, so in the example above, users are relying on `gpgtools.org` to serve the correct file (hosting infrastructure is secure, admins are trustworthy, etc) and TLS certificate authority must not be compromised.

There _was_ a very long and drawn out attempt to add gpg sig verification:

* https://github.com/Homebrew/homebrew-cask/pull/8749
* https://github.com/Homebrew/homebrew-cask/pull/16090
* https://github.com/Homebrew/brew/pull/1335

But then it was just closed before being merged...

Something called "gpg stanza" was enabled for a while, but deprecated because of this comment:
[Homebrew/4120#comment-406879969](https://github.com/Homebrew/brew/pull/4120#issuecomment-406879969)

I disagree with that comment.

The author seems to believe that Homebrew maintainers would have to verify real-world identities  and / or that signature checking would confuse some users.

My response:

1. PGP signatures should be optional for a formula (for packages that publish these)
2. PGP signatures checking should be optional for users (off by default).
3. Authenticity:
   - The signatures check happens locally using the users's personal trust database.
   - The signatures can be verified, but it is up to the user to *choose* the level of trust assigned to that key.  Homebrew maintainers don't need to worry about that.

Unfortunately this decision to exclude signatures means one cannot have signature checking AND use homebrew (which offers nice package management!).

### What is a security-conscious user supposed to do then?

You can download the package yourself and check the signature, then take the SHA-256 hash and compare it to the one used in the corresponding Homebrew formula.  If they are identical and you trust the signature, then you can install via `brew`.

You can of course also compile it yourself, but this doesn't help much if the source is not signed.

### What if my package doesn't provide signed releases?

Make use of whatever you have and / or don't use packages that don't care about user security.

### What about deterministic builds?

Sounds great, I hope it will become the norm for all projects in the future. Unfortunately very few projects offer this today.  Without signatures on the builds, you also don't know if the code was tampered with / which one is correct.

### Can hashes without signatures help at all?

Homebrew provides a broadly used and reviewed source of SHA-256 hashes.  This can still provide some evidence _suggesting_ which packages are being served by the so called "official" project domain.  Users can download a package multiple times, from various IP addresses at different times and check that all of the hashes match what is in Homebrew.  This at least suggests that you are not being individually targeted and increases the likelihood that the attacker would be caught while trying to fool everybody.

A Google search for a SHA-256 hash can help with the above process as well.

In many cases, this is the best option available unless you know the author personally.

As someone interested in contributing to this process for others, [I publish hashes for various packages](https://github.com/jonathancross/jc-docs/blob/master/Software_Hashes.md) so that others can use my info to try and crowd-source some sense of package authenticity.

There is also the Apple developer signatures on most (?) apps for MacOS as well...

Sad, but this is the state of things today 2018-09-27.

[Feedback / corrections](https://github.com/jonathancross/jc-docs/issues/new?title=Feedback:%20Homebrew_GPG) are welcome and appreciated.

Jonathan Cross

### License

WTFPL - See [LICENSE](https://github.com/jonathancross/jc-docs/blob/master/LICENSE) for more info.
