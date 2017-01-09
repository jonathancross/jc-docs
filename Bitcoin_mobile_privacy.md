Bitcoin mobile privacy via Trusted peer over Tor
================================================

TL;DR; This guide will help you easily configure an Android Bitcoin Wallet to relay transactions via a trusted Full Node using Tor, therefore mitigating the most important security and privacy concerns on mobile devices.

## Intro

Bitcoin mobile clients generally offer significantly reduced security and privacy in comparison to a full node. For many users, this is an unfortunate, but seemingly necessary usability compromise. Wallets have attempted to address the issues in several ways, but all have significant downsides. This guide presents a practical setup for enhanced privacy and security on mobile devices. Specifically, the guide below describes how to use the [Bitcoin Wallet for Android](https://play.google.com/store/apps/details?id=de.schildbach.wallet) and its "Trusted peer" option with a Tor hidden service to avoid several critical issues without sacrificing usability.  This guide does not cover any of the issues related to endpoint security (keeping your Android device and full node secure) or analysis of the Bitcoin blockchain.

Contents:
* [Background](#background)
* [Setup & Configuration](#setup--configuration)
* [Alternatives](#alternatives)
* [FAQ](#faq)
* [Conclusion](#conclusion)


## Background

#### Privacy:
Privacy in the context of Bitcoin is a complex, multifaceted issue.  Here we will be focusing on addressing [privacy issues related to Bloom filters](https://eprint.iacr.org/2014/763.pdf), passive surveillance of transactions and capturing of IP addresses that broadcast a transaction.  Basically everything that happens before transactions are collected by miners and written to the blockchain.  There are many other privacy issues in the context of blockchain analysis, but those can be addressed in other ways and are out of scope for this document.


Issues with SPV clients and Bloom filters:

1. The Bitcoin Wallet for Android, relies on [Bloom filters](https://github.com/bitcoin/bips/blob/master/bip-0037.mediawiki) to protect user privacy.  However it has been demonstrated that this is ineffective and connected peers can easily discover which addresses are owned by the user.
2. A passive observer controlling many nodes can pinpoint the IP address of the node which is first to broadcast a transaction. This information can then be used for geolocation, address clustering, etc.  This is unrelated to Bloom filter information leakage, but can be used to link transactions to a specific actual user.  Bitcoin full nodes are less vulnerable to this sort of data collection because they are constantly relaying not only their own transactions, but all transactions on the network.

#### Security:
Without access to the full blockchain, payments can potentially be blocked and peers can hypothetically lie about (withhold) transactions from SPV clients.


### Trusted peer:
The original Bitcoin Wallet for Android introduced a so called **Trusted peer** option allowing the wallet to communicate directly with a full node which the user presumably controls. This theoretically offers the benefits of a full node on a light client (assuming your connection to the node is secure).

In order to prevent a [Man In The Middle attack](https://en.wikipedia.org/wiki/Man-in-the-middle_attack), the connection to the "Trusted peer" must be secure - ie both authenticated and encrypted.  However, it is left to the user to figure out this crucial piece.


## Approach presented here:
Trusted peer connecting to self hosted Tor hidden service.

Benefits:

1. Provides **authentication** as the hidden service name itself is derived from the public key, preventing impersonation.

2. All **traffic is encrypted** preventing passive surveillance.

3. Data packets are **protected against manipulation** by intermediate nodes.

4. The Tor network hides the user’s IP address.  This frustrates attempts to **geolocate transactions** and **clustering Bitcoin addresses** per IP address.

5. If you own the Trusted peer, then you can be reasonably confident that a **third party is not monitoring transactions** before they are broadcast on the Bitcoin network.

Essentially we resolve the most significant issues inherent in a mobile wallet client using existing software.

# Setup & Configuration

## Trusted peer
This setup will require a [Bitcoin Core full node](https://bitcoin.org/en/full-node) which you trust, ie a secure desktop computer (ideally running Linux, etc) and available 24/7.  Can also be a close friend you trust not to spy on your transactions or make stupid configuration errors.  Although it is possible to host the full node on a remote server (ie Digital Ocean), this will undermine the trustlessness we are trying to achieve here, so it is not recommended.  You will also run a Tor proxy on the system allowing your mobile to connect securely to the server.

1. Install and [configure Tor](https://www.torproject.org/docs/installguide.html.en), then ensure it is properly routing traffic over the Tor network.
2. [Install Bitcoin Core](https://bitcoin.org/en/download).  The wallet can be disabled, you only need `bitcoind`.
3. [Configure Bitcoin Core to run as a Tor hidden service](https://github.com/bitcoin/bitcoin/blob/master/doc/tor.md).<br>**IMPORATANT** Do not skip this step as this provides all the security / privacy benefits outlined here.
4. Use the Tor hidden service as the "Trusted peer" as shown in the Android Bitcoin Wallet screen shots below.

Once you have it all setup, you can [check your Tor hidden service is recognized on the bitcoin network](https://bitnodes.21.co/nodes/) and then configure your mobile to use the `.onion` address as shown below.

## Android
You will need to install [Orbot](https://play.google.com/store/apps/details?id=org.torproject.android) (Tor Client for Android) and [Bitcoin Wallet for Android](https://play.google.com/store/apps/details?id=de.schildbach.wallet).

#### Setup Bitcoin Wallet Trusted peer

![bitcoin-wallet-settings](images/1.bitcoin-wallet-settings.png)
![bitcoin-wallet-trusted-peer](images/2.bitcoin-wallet-trusted-peer.png)

Once the **Trusted peer** is configured with your `.onion` hidden service, you will see only a single node connected on a private IP address (`10.xx.xx.xx` in this example).

#### Setup Orbot

![orbot-vpn-enabled](images/3.orbot-vpn-enabled.png)
![orbot-settings](images/4.orbot-settings.png)
![orbot-settings-apps-vpn](images/5.orbot-settings-apps-vpn.png)

Use Orbot's **Apps VPN Mode** which allows the wallet app to connect to your Tor hidden service.


### Metadata

Note that this setup will protect your **transactions** from passive surveillance, however the Android Wallet requires additional information via `https` when constructing the transaction:

1. BIP70 payment request.
2. Current fee data is requested from a server controlled by [Bitcoin Wallet developers](https://play.google.com/store/apps/dev?id=5750589945930020869). (public data)
3. Exchange rate feed from bitcoinaverage.com. (public data)

This data is transferred over https and tunneled through Tor, so they do involve exit nodes which *could* try and spy on you.  A malicious entrance node might harvest your IP address and a little metadata, but nothing of real value because the connection is authenticated and data is encrypted.

These connections should therefore not present serious privacy / security concerns, but are good to be aware of.


# Alternatives

This is by no means the only way to safely run a Bitcoin light client.

Here are a couple other possibilities:

1. [Electrum for Android](https://play.google.com/store/apps/details?id=org.electrum.electrum) with your own Electrum server.
2. Use a standard VPN or SSH tunnel to route traffic over secure connection from your mobile device to your own full node.

Both options may also use Tor to further obfuscate your IP address.


# FAQ

#### Q: Do I have to setup a full node?
A: Yes: on hardware you control.

#### Q: Do I have to setup a Tor Hidden service?
A: Yes: This allows you to avoid exit nodes that **will** spy on your unencrypted traffic.

#### Q: Is it Dangerous to setup a Tor Hidden Service?
A: Normally not.  We are not doing anything illegal here.  You should not run an exit node (that is dangerous).  You can block relaying, etc if you want to be safer.

#### Q: Is Tor Broken?
A: No. Tor is less anonymous than people once thought and is easy to misuse and misunderstand.   Using Tor exactly as outlined above provides a clear security + privacy benefit.

#### Q: Why should I go to all this trouble?
A: Because you believe in freedom enough to experiment with cryptocurrency maybe?

# Conclusion

### Acknowledgments

Thanks to [Andreas Schildbach](https://github.com/schildbach) (Bitcoin Wallet for Android) and [Jonas Schnelli](https://github.com/jonasschnelli) (Bitcoin Core developer) for their input and feedback.

### Disclaimer

This document comes with no guarantees, do your own homework :-) **[Feedback is welcome!](https://github.com/jonathancross/jc-docs/issues/new?title=Feedback: Bitcoin mobile privacy)**

### License

CC0 1.0 Universal - See [LICENSE](https://github.com/jonathancross/jc-docs/blob/master/LICENSE) for more info.
