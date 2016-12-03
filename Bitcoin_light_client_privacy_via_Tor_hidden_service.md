[draft] Bitcoin light client privacy via trusted peer as Tor hidden service
===========================================================================

Bitcoin light clients generally offer significantly reduced security and privacy in comparison to a full node. For many users, this is an unfortunate, but necessary compromise required when using Bitcoin on a mobile device. Wallets have attempted to address the issues in several ways, but all have significant downsides. Here I will present a practical solution providing enhanced privacy to Bitcoin users on mobile devices.

#### Privacy:
Privacy in the context of Bitcoin is a complex, multifaceted issue.  Here we will be focusing on addressing privacy issues related to bloom filters used in SPV wallets and geographic location of transaction broadcast.  Basically everything that happens before transactions are written to the blockchain.  There are many other issues in the context of blockchain analysis, but those can be addresses in other ways and are out of scope for this document.


#### Issues:
1. Bloom filters leak all addresses to connected SPV peers.
2. If the user connects to a third party server (as in Electrum, Mycelium, etc), all transactions can be monitored.
3. When a transaction is broadcast, passive observers can often pinpoint the IP address that broadcast the transaction, then use this for geolocation, address clustering, etc.


#### Security:
Without access to the full blockchain, payments can potentially be blocked and peers can lie about transactions received.


## Trusted peer:
Some wallets such as the original [Bitcoin Wallet for Android](https://play.google.com/store/apps/details?id=de.schildbach.wallet) have introduced a so called **"Trusted peer"** option to allow a light client to connect directly to a full node the user controls. A "Trusted peer" theoretically offers the benefits of a full node on light clients assuming your connection to the node is secure.


#### Protecting against a MITM attack:
In order to prevent a [Man In The Middle attack](https://en.wikipedia.org/wiki/Man-in-the-middle_attack), the connection to the "Trusted peer" must be both authenticated and encrypted.


## Proposed solution:
Trusted peer connecting to self hosted Tor hidden service.

Benefits:

1. Provides **authentication** as the hidden service name itself is derived from the public key, preventing impersonation.

2. All **traffic is encrypted** preventing passive surveillance.

3. Data packets are **protected against manipulation** by intermediate nodes.

4. The Tor network hides the user’s IP address.  This frustrates attempts to **geolocate transactions** and **clustering Bitcoin addresses** per IP address.


# Setup & Configuration

## Trusted peer
This setup will require a [Bitcoin Core full node](https://bitcoin.org/en/full-node) which you trust, ie a secure desktop computer (ideally running Linux) and available 24/7.  Can also be a close friend you trust not to spy on your transactions or make stupid configuration errors.  You can use a remote server (ie Digital Ocean, etc) but realize this undermines much of the trustlessness we are trying to achieve here.

1. Install and [configure Tor](https://www.torproject.org/docs/installguide.html.en) and ensure it is accepting incomming connections.
2. Setup Bitcoin Core and confirm it is working correctly.  You do not need the wallet, just bitcoind.
3. [Configure Bitcoin Core to run as a Tor hidden service](https://github.com/bitcoin/bitcoin/blob/master/doc/tor.md).
4. Use the Tor hidden service as the "Trusted peer" as shown in the Android Bitcoin Wallet screenshots below.

## Android
You will need to install [Orbot](https://play.google.com/store/apps/details?id=org.torproject.android) (Tor Client for Android) and [Bitcoin Wallet for Android](https://play.google.com/store/apps/details?id=de.schildbach.wallet).

#### Bitcoin Wallet Trusted peer

![bitcoin-wallet-settings](Bitcoin_light_client_privacy_via_Tor_hidden_service/1.bitcoin-wallet-settings.png)
![bitcoin-wallet-trusted-peer](Bitcoin_light_client_privacy_via_Tor_hidden_service/2.bitcoin-wallet-trusted-peer.png)

#### Orbot

![orbot-vpn-enabled](Bitcoin_light_client_privacy_via_Tor_hidden_service/3.orbot-vpn-enabled.png)
![orbot-settings](Bitcoin_light_client_privacy_via_Tor_hidden_service/4.orbot-settings.png)
![orbot-settings-apps-vpn](Bitcoin_light_client_privacy_via_Tor_hidden_service/5.orbot-settings-apps-vpn.png)
