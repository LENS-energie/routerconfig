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

# Install packages
apt-get install dnsmasq autossh ufw sg3-utils openssh-server logrotate vnstat git

# Clean up
apt-get clean

# Create TFTP-directory
mkdir /var/ftpd

# Install log2ram
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

### Modems and mode-switching

If you use a "HiLink" USB-modem such as the Huawei E303 or E3256, you will need to set the APN of your SIM-provider using the configuration page of the modem. You can probably do this on a Windows-computer using the drivers provided by Huawei, or on a Linux-computer by mode-switching the device and pointing your web-browser to the IP-address of the modem (e.g. http://192.168.1.1 or http://192.168.8.1). Mode-switching is needed to tell the USB-modem it should behave as a modem rather than pretending it's a CD-ROM with Windows-drivers. Unfortunately the process is somewhat device-dependent. If you install `sg3-utils`, the following works for some Huawei-modems: 

```
sudo /usr/bin/sg_raw /dev/sr0 11 06 20 00 00 00 00 00 01 00
```

The configuration in this repository already has a udev-file that will automatically mode-switch such Huawei USB-modems. For other modems, it's probably a good idea to use the [usb_modeswitch](http://www.draisberghof.de/usb_modeswitch/)-tool.


### Analysis tools

Before rebooting, you may want to install some additional analysis tools, in case you run into problems:
 - `apt-get install traceroute bind9-host usbutils` will give you the commands `traceroute`, `host` and `lsusb`.
 - `apt-get install bmon tcptrack iptraf` will allow you to analyse network traffic in more detail.


### Cloning your SD-card

Once you have installed and tested the router, you can make an image of the SD-card for easy cloning. However, recent versions of Debian (including Raspbian) include a feature called [predictable network interface names](https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/), which will interfere with cloning if not disabled. The problem is that the system remembers the MAC-address of your network interfaces (which are unique for every device), and assigns a new network device to each new MAC. However, the configuration files above expect the LAN (UTP-device) to be eth0 and the WAN (modem, etc.) to be eth1. There are at least three ways around this:

1. Hand-edit the rules file (usually `70-persistent-net.rules` or `80-net-setup-link.rules`) in `/etc/udev/rules.d/` for every new device, so that eth0 and eth1 are assigned correctly.
2. Remove the rules file (or at least the entries in the file) before making an image of the SD-card. Upon first boot on new hardware, new rules will be created (and can be modified if needed).
3. Disable predictable network interface names alltogether by linking the rules-file to `/dev/null`. In this case you need to trust the kernel to assign network device names correctly (which is usually not a problem, as the built-in UTP-device is generally detected first and assigned eth0).

To make an image of the SD-card on a Linux-system and copy it to a new SD-card, perform the following steps:

1. Insert the card in a card-reader. If it is auto-mounted, run `mount` in a terminal to find out the device names of the boot- and root-partions on the card (e.g. `/dev/sdb1` and `/dev/sdb2`). If it is not auto-mounted (e.g. in Ubuntu server or Raspbian), run `dmesg` to find out the device name of the card (e.g. `/dev/sdb`).
2. If the partitions have been auto-mounted, unmount them in the terminal (e.g. `sudo umount /dev/sdb1 ; sudo umount /dev/sdb2`).
3. Use `dd` or `dcfldd` to copy the SD-card device to a file (e.g. `sudo dd if=/dev/sdb of=minibian-gprsrouter.img`).
4. Remove the SD-card and insert an empty SD-card. Double-check that you are using the correct device name (important to avoid overwriting your entire harddisk!!) and copy the image to the new card (e.g. `sudo dd if=minibian-gprsrouter.img of=/dev/sdb`).

If you want to check or modify the image directly, you can mount its boot- and root-partition using `kpartx` (e.g. `sudo kpartx -v -a minibian-gprsrouter.img`).


### Setting up a reverse SSH-tunnel for remote access

Example `/usr/local/bin/start-ssh-tunnel.sh`:

```
#!/bin/sh

# Set up a reverse SSH tunnel, so your device can be reached through another server,
# even if it is located behind a firewall without port forwarding.
# Obviously this will require a remote SSH-server and an SSH-shell-account on that server.

remote_server=ssh.mydomain.com
remote_user=remoteuser
remote_port_ssh=2200

test_network="ping -q -c2 google.com >/dev/null"

# Wait for network to become ready
until $(eval $test_network); do
    sleep 30
done

# Setup a reverse tunnel with compression using autossh
autossh -f -nNTC -R $remote_server:$remote_port_ssh:localhost:22 $remote_user@$remote_server

# Don't forget to push your local SSH-key to the remote server before running this script, e.g.:
# ssh-copy-id remoteuser@ssh.mydomain.com
# When the script is running, you can connect to your tunnel using e.g.:
# ssh -p 2200 localuser@ssh.mydomain.com
```
