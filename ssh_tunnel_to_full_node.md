# Using an ssh tunnel to connect to a node

This is a very rough guide that can help you secure a remote connection to your Monero node.  This doesn't work for nodes you do not control.  Instructions for Bitcoin are at the bottom.

## Features

- Works today with existing software.
- Doesn't expose your node's RPC port to the outside world.
- Desktop / Laptop & Android support.
- Works for both Monero and Bitcoin.

## Remote node setup

1. Setup your remote node on a server/vps and ensure it is working.  You will need a static IP address or hostname.
   - Install and sync `monerod`.
   - Configure it to accept localhost RPC commands and secure via username & password.
   - Make sure RPC commands are working when you are ssh'd into the server.
   - Settings for `~/.bitmonero/bitmonero.conf`
   ```
   # Careful with the password as special characters can easily break your setup.
   # Avoid these chars for compatibility: @`:"#'%$&=*
   rpc-login=USER_NAME:PASSWORD
   # Size 40 here helps make wallets 'feel' more responsive on mobile.
   block-sync-size=40 # Default is 200 blocks per batch.
   ```

2. Create a new user for tunneling: `useradd sshtunnel -m -d /home/sshtunnel -s /bin/true`
   - See [Hardening](#hardening) below to secure this user account.

## Client

### Desktop computer (Linux / Mac explained below, sorry Windows users)

1. Create a new ssh key pair: `ssh-keygen -t rsa -b 4096`
   - 4096 bit RSA is fine, as is `ed25519` (same curve used in Monero)
2. Show the pubkey: `cat ~/.ssh/id_rsa.pub`
3. Log into the **remote** node and append the pubkey to the user's authorized_keys file: `echo "YOUR_PUBKEY_LINE_HERE" >> ~/.ssh/authorized_keys`

You should now be able to tunnel packets to your node.

#### Open a tunnel for Monero GUI

1. Create an ssh tunnel forwarding port `18081` to the remote node: `ssh -nNT -L 18081:localhost:18081 user@host` (change `user@host` to the "username" you created above and name / ip address of your node)
2. As long as it doesn't fail, you can then open up the Monero GUI and configure a "Remote node" as:
   - Address: `localhost`
   - Port: `18081`
   - Click on "Show advanced", then add username and password for the RPC server.
   - Click "Connect"

If all went well, you should see the GUI start to load blocks after a minute or so.  It may feel faster if you configure your node to use smaller batches of blocks, eg: `block-sync-size=20`

### Android

#### Connectbot ssh

1. Install Connectbot ([Google Play](https://play.google.com/store/apps/details?id=org.connectbot&hl=en) | [APK](https://github.com/connectbot/connectbot/releases/latest))
2. Create a new ssh key.
3. Somehow get the public key line into your remote `~/.ssh/authorized_keys` file.
4. Add a new host with the remote info 
   - `user@host` should be the "username" you created above and name / ip address of your node
5. After the host is saved, you can then long-press on the hostname and select "**Edit port forwards**"
   - Nickname: Monero rpc
   - Type: Local
   - Source port: `18081`
   - Destination: `localhost:18081`
6. Click "Create port forward"
7. Go back to the main screen.
8. Tap on the host you created to connect.
9. You should see some stuff flash in the terminal, but then it just has a cursor in the middle and is black.

#### Monerujo

1. Install the [Monerujo](https://www.monerujo.io/) Monero wallet and configure it to connect to: `RPC_USER:RPC_PASSWORD@localhost:1081` where:
   - `RPC_USER` is the username on the remote Monero node
   - `RPC_PASSWORD` is the password you created. Both can be found in the `.bitmonero/monero.conf` file on your server / vps.


That should be everything, good luck!


## Bitcoin

You can duplicate the same setup above to run a full Bitcoin node and connect to it using [Samourai Wallet](https://samouraiwallet.com/) and its [Trusted Node](https://samouraiwallet.com/features/trustednode) feature. 
**Note:** port number will be `8332` instead of `18081` above.  Connectbot allows multiple Port forwards.

## Hardening

- You should restrict everything possible on your node to make sure the ssh tunnel user has no shell, and can only tunnel tcp traffic on the ports specified.
- Prevent password login on the server completely

Some useful settings to add to your server's ssh config file: `/etc/ssh/sshd_config`

```
# Disable passwords (only use public key auth)
PasswordAuthentication no

# Prevent root from logging in directly.
# Instead you should login as a another user, and use 'su' or 'sudo' to do what you need.
# Don't change this until you really know what you are doing, don't want to lock yourself out. 
# PermitRootLogin no

# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes
# For this to work you will also need host keys in /etc/ssh_known_hosts
RhostsRSAAuthentication no
# similar for protocol version 2
HostbasedAuthentication no
# To enable empty passwords, change to yes (NOT RECOMMENDED)
PermitEmptyPasswords no

# List all accounts you want to let use ssh (separated by a space).
AllowUsers my_normal_user sshtunnel

# Restrict the sshtunnel user to only access Monero and Bitcoin node ports.
Match User sshtunnel
  PermitOpen localhost:18081 localhost:8332
  X11Forwarding no
  AllowAgentForwarding no
  ForceCommand /bin/false
```

**Note:** you need to restart ssh (usually `sudo service ssh restart`) for changes to take place.

# Tor

You can configure [Orbot](https://guardianproject.info/apps/orbot/)'s VPN mode on your Android device to capture and route Connectbot traffic over the Tor network.  This will allow the ssh tunnel connections to your full node to route through Tor.  This only offers limited privacy if the server is in your name, but still helps. You do not need to configure a Tor hidden service for this to work.

# Conclusion

### Other options

- Monerujo is [working on adding Tor support](https://github.com/m2049r/xmrwallet/issues/100).  This could allow us to potentially remove Connectbot from the setup above, and instead run our node as a Tor hidden service. Here is a guide explaining how to [setup a Monero node at hidden service](https://garlicgambit.wordpress.com/2017/01/15/monero-how-to-connect-wallet-to-tor-onion-service-node/).
- Eventually we expect to have Monero nodes integrated with I2P via [Kovri](https://getkovri.org).  This may eventually allow us to use an I2P tunnel to connect to a node instead of ssh.  This probably won't be stable until 2020 or so.

### Disclaimer

This document comes with no guarantees, do your own homework.  [Feedback](https://github.com/jonathancross/jc-docs/issues/new?title=Feedback:%20ssh_tunnel) is welcome and appreciated.

### License

WTFPL - See [LICENSE](LICENSE) for more info.
