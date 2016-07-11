

After a fresh install of Minibian or Dietpi, install the files from this repository and perform the following steps:


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

# Initialise stuff 
mkdir /var/ftpd
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
