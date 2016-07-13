# Cellular router

These files contain the basic configuration used to turn a Raspberry Pi running [Minibian](https://minibianpi.wordpress.com) or [DietPi](http://dietpi.com/) into a cellular (GPRS/3G/4G) router. Our current setup uses a Huawei E303 HSPA USB Stick. Parts of this configuration were based on <http://techmind.org/rpi/>.

After a fresh install of Minibian or Dietpi, install the files from this repository and perform the following steps (as root):


```
# Set password and generate SSH-key for the root account
passwd
ssh-keygen

# Update the system
apt-get update
apt-get upgrade
apt-get dist-upgrade

# Install packages (the last two are optional)
apt-get install dnsmasq autossh ufw sg3-utils openssh-server logrotate vnstat joe git

# Clean up
apt-get clean

# Create TFTP-directory

# Install log2ram
mkdir /var/ftpd
cd /root
git clone https://github.com/azlux/log2ram.git
cd /root/log2ram
sh install.sh
```

The default configuration is as follows:
 - eth0 has a static IP-address: 192.168.42.1
 - eth1 gets a dynamic IP-address over DHCP (e.g. from a Huawei E303 HSPA-modem)
 - dnsmasq is configured to cache DNS-requests and run a DHCP-server on eth0
 - IP-masquerading is configured from eth0 to eth1
 - log2ram is used to store the system logfiles on ramdisk
 - logrotate is used to limit the size of the logfiles
 - internet connectivity and eth0 IP are checked every hour, system is rebooted if down
 - The script `/usr/local/bin/start-ssh-tunnel.sh` is run on boot, to set up a reverse SSH-tunnel (optional, and requires ssh-copy-id to the server)
 - vnstat can be used to check network traffic stats

Example /usr/local/bin/start-ssh-tunnel.sh:

```
#!/bin/sh

# Set up a reverse SSH tunnel, so your device can be reached through another server,
# even if it is located behind a firewall without port forwarding.
# Obviously this will require a remote SSH-server and an SSH-shell-account on that server.

remote_server=ssh.mydomain.com
remote_user=remoteuser
remote_port=2200

test_network="ping -q -c2 google.com >/dev/null"

# Wait for network to become ready
until $(eval $test_network); do
    sleep 30
done

# Setup a reverse tunnel using autossh
autossh -f -nNT -R $remote_server:$remote_port:localhost:22 $remote_user@$remote_server

# Don't forget to push your local SSH-key to the remote server before running this script, e.g.:
# ssh-copy-id remoteuser@ssh.mydomain.com
# When the script is running, you can connect to your tunnel using e.g.:
# ssh -p 2200 localuser@ssh.mydomain.com
```
